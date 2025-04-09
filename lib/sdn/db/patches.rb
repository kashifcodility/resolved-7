##
## Patch the other frameworks with our ju-ju.  We do it here instead of
## PatchLoader because load order is important and we depend on it (PL can come
## after our load).  Another reason is because we don't want DB-specific patches
## loaded in/for components that don't have DB support.
##
#
# TODO: make this better organized!  db/patches.rb, db/patches/*, etc.

# ---- dm_types_json_migration
# NOTES
#
#  - when dm-migrations/dm-do-adapter migrates properties
#    - Text: type_map[Property::Text] yields schema of TEXT with no :length property (works)
#    - Json: type_map[property.class] fails because custom types can't/don't update type_map
#      - type_map[property.primitive] kicks in == type_map[Property::String]
#      - type_map[Property::String] yields schema of VARCHAR that has :length property
#      - later on, DM core detects primitive String, :length => bigger_than_string and upgrades to MEDIUMTEXT
#      - result: MEDIUMTEXT(123412341234) == FUCKED
#
#  - solution: custom property is recognized in type_map
#
# *  a. allow custom properties to add entries to adapter's type_map
#      - instance variable is in adapter-specific class; no way to "get them all" operating on DOAdapter
#
#      new_tm = ::DataMapper::Adapters::MysqlAdapter.instance_variable_get(:@type_map).dup
#      new_tm[::DataMapper::Property::Json] = new_tm[::DataMapper::Property::Text]
#      ::DataMapper::Adapters::MysqlAdapter.instance_variable_set(:@type_map, new_tm)
#
#    b. make type_map able to detect derived classes (Json < Text)
#      - can be handled from dm-migrations/dm-do-adapter's property_schema_hash
#      - deferred for now
#
# This patch implements (a).

class ::DataMapper::Adapters::MysqlAdapter

    # Trigger anyone who has overridden type_map with a super call
    new_tm = type_map.dup
    new_tm[::DataMapper::Property::Json] = new_tm[::DataMapper::Property::Text]
    instance_variable_set(:@type_map, new_tm)

end if defined? ::DataMapper::Adapters::MysqlAdapter


# Monkey patch to old code which checks max_size for being a Fixnum (which is
# now an Integer).  This prevents the deprecation warning.

module DataObjects::Pooling
    class Pool
        def initialize(max_size, resource, args)
            raise ArgumentError.new("+max_size+ should be a Integer but was #{max_size.inspect}") unless Integer === max_size
            raise ArgumentError.new("+resource+ should be a Class but was #{resource.inspect}") unless Class === resource

            @max_size = max_size
            @resource = resource
            @args = args

            @available = []
            @used      = {}
            DataObjects::Pooling.append_pool(self)
        end
    end
end

# Patch to try and get "back" to Ruby 1.8.7 behaviour, WRT precision w/
# BigDecimals vs. Floats.
#
# Observe:
#
#   1.8.7 :003 > Float(80.784).to_d.to_s('F')
#   => "80.784"
#
#   1.9.3p194 :003 > Float(80.784).to_d.to_s('F')
#   => "80.78400000000001"
#
# Generally we assign Floats to price-related fields (BigDecimal).  DM's
# validation "validates_numeric", which enforces precision/scale by forcing the
# original Float through BigDecimal->String conversion, then uses a regex to
# confirm the scale/precision match.  In the case where the precision of the
# number being assigned exceeds the possible precision/scale, the validator
# errors out with "XXX must be a number".
#
# If we force the value to string upon assignment - *before* typecasting - we
# will avoid the Numeric validator's conversion and get back to the 1.8.7
# behaviour.
#
# NOTE: At 5 digits of precision, Floats will #to_s as Floats.  At the sixth and
# beyond, Floats will #to_s as Scientific Notation, which once again fails the
# validator (e.g. AL#amount).  Now we rely on the fact that BigDecimal#to_s has
# an F option that avoids Scientific Notation, and BigDecimal(String) ignores
# any internal precision limits.  This approach is even less efficient, but WTF
# is there left to do?  At least the goddamn thing works.

module DataMapper
    class Property
        class Decimal < Numeric
            alias_method :typecast_to_primitive_original, :typecast_to_primitive
            def typecast_to_primitive(value)
                typecast_to_primitive_original(BigDecimal(value.to_s).to_s('F'))
            end
        end
    end
end


::DataMapper::Model.module_eval      { include SDN::Mixins::Paginator::ClassMethods }
::DataMapper::Collection.module_eval { include SDN::Mixins::Paginator::ClassMethods }


=begin

# WARN: this is being disabled because it may no longer be necessary, now that
# the DataObjects Pooling bug has been fixed.  Uncomment this code if the "MySQL
# connection has gone away" bug resurfaces.


# MySQL kills idle connections.  Sometimes we don't have much website traffic,
# so we end up exceeding the db-configured idle timeout.  We need to keep that
# timeout in place so the DB cleans up legitimately dead connections and not
# eventually DoS itself.  However, so long as we're around (app server), we need
# to keepalive the connection.  Arbitrarily picking 1 hour as an interval.

require 'sdn/scheduler'

class Schedule
    def data_objects_keepalive
        $LOG.info "schedule: db conn keep-alive"
        $DB.execute("SELECT 1")
    ensure
        $SCHEDULER.in(30.minutes, :data_objects_keepalive)
    end
end

$SCHEDULER.asap(:data_objects_keepalive)

=end


# This following insanity is necessary to hook whenever a new connection is
# actually created (vs retrieved from the connection Pool).  We do this so we
# can override the connection/session-specific sql_mode, which is embedded
# inside the C driver.
#
# Context: Newer MySQL enables sql_mode ONLY_FULL_GROUP_BY on when ANSI is set.
# This normally isn't a problem for us; however some of the old nasty-ass PHP
# SQL queries aren't compatible so we disable it.  DataObjects sets ANSI mode
# inside the driver, so we explictly override it immediately afterwards.

require 'do_mysql'

class DataObjects::Mysql::Connection
    class << self
        alias_method :old_new, :new
        def new(*args)
            new_conn = old_new(*args)
            concrete_command.new(new_conn,
                                 "SET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES,NO_DIR_IN_CREATE," +
                                 "NO_ENGINE_SUBSTITUTION,NO_UNSIGNED_SUBTRACTION,TRADITIONAL," +
                                 "REAL_AS_FLOAT,PIPES_AS_CONCAT,ANSI_QUOTES,IGNORE_SPACE'"
                                ).execute_non_query
            return new_conn
        end
    end
end
