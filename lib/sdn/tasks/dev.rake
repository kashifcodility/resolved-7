namespace :dev do

    BACKUP_DIR = "/tmp/"

    task :dump_db do
        ensure_in_frontend # for a working database.yml

        dump_name = ARGV.last
        if dump_name.include?("dump_db")
            puts "usage: rake dev:dump_db <dump_name>"
            puts "data will be backed up in /tmp/<dump_name>"
            exit(-1)
        end

        each_repo_do do |repo, conf|
            case conf[:adapter]
            when 'mysql'
                mysql_dump(conf[:database], dump_name)
            else
                raise "Unknown adapter type #{conf[:adapter]}"
            end
        end

        # Local blob store.. when we start using one.
        #datastore_dump(dump_name)

        exit 0
    end

    task :restore_db do
        ensure_in_frontend # for a working database.yml

        dump_name = ARGV.last
        if dump_name.include?("restore_db")
            puts "usage: rake dev:restore_db <dump_name>"
            puts "data will be restored from /tmp/<dump_name>"
            exit(-1)
        end

        each_repo_do do |repo, conf|
            case conf[:adapter]
            when 'mysql'
                mysql_restore(conf[:database], dump_name)
            when 'mongoid'
                mongo_restore(conf[:database], dump_name)
            else
                raise "Unknown adapter type #{conf[:adapter]}"
            end
        end

        datastore_restore(dump_name)
        exit 0
    end

    def each_repo_do
        require 'sdn/config'

        db_conf_file = 'config/database.yml'
        db_conf = ::SDN::Config.load(db_conf_file)
        raise InvalidConfig, "no repositories in #{db_conf_file}" if db_conf[:repositories].blank?

        db_conf[:repositories].each do |repo, conf|
            yield(repo, conf)
        end
    end

    def run_or_die(cmd)
        unless system(cmd)
            puts "Failed to execute #{cmd}"
            exit(-1)
        end
    end

    def ensure_dump_dir(dump_name)
        run_or_die("mkdir -p  #{BACKUP_DIR}#{dump_name}/")
    end

    def ensure_has_dump_dir(dump_name)
        dir_path = "#{BACKUP_DIR}#{dump_name}/"
        unless File.directory?(dir_path)
            puts "Directory #{dir_path} does not exist! Cannot restore from it"
            exit(-1)
        end
    end

    def ensure_in_frontend
        cur_dir = Dir.pwd.split("/").last
        unless cur_dir == "frontend"
            puts "Must run in eli application dir"
            exit(-1)
        end
    end

    def delete_dir(dir)
        run_or_die("rm -rf #{dir}/")
    end

    def mysql_dump(db_name, dump_name)
        puts "Dumping mysql db #{db_name} to #{dump_name}"
        ensure_dump_dir(dump_name)
        run_or_die("mysqldump -u sdnadmin #{db_name} | xz > #{BACKUP_DIR}#{dump_name}/#{db_name}.sql.xz")
    end

    def mysql_restore(db_name, dump_name)
        puts "Restoring mysql db #{db_name} from #{dump_name}"
        ensure_has_dump_dir(dump_name)
        run_or_die("xz -dc #{BACKUP_DIR}#{dump_name}/#{db_name}.sql.xz | mysql -u sdnadmin #{db_name}")
    end

    def datastore_dump(dump_name)
        puts "Dumping data dir to #{dump_name}"
        ensure_dump_dir(dump_name)
        run_or_die("tar -cf #{BACKUP_DIR}#{dump_name}/data.tar data/")
    end

    def datastore_restore(dump_name)
        puts "Restoring data dir from #{dump_name}"
        ensure_has_dump_dir(dump_name)
        delete_dir("data/")
        run_or_die("tar -xf #{BACKUP_DIR}#{dump_name}/data.tar data/")
    end
end
