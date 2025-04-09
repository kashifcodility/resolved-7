module SDN::DB::Property
    class Email < ::DataMapper::Property::String

        # Ganked from
        # https://raw.github.com/datamapper/dm-validations/master/lib/data_mapper/validation/rule/formats/email.rb
        #
        # Unfortunately doesn't invalidate 'foo@foo..com'.  Issue logged:
        # https://github.com/datamapper/dm-validations/issues/60
        def valid_email_format_latest
            if (RUBY_VERSION == '1.9.2' && RUBY_ENGINE == 'jruby' && JRUBY_VERSION <= '1.6.3') || RUBY_VERSION == '1.9.3'
                # There is an obscure bug in jruby 1.6 that prevents matching
                # on unicode properties here. Remove this logic branch once
                # a stable jruby release fixes this.
                #
                # http://jira.codehaus.org/browse/JRUBY-5622
                #
                # There is a similar bug in preview releases of 1.9.3
                #
                # http://redmine.ruby-lang.org/issues/5126
                letter = 'a-zA-Z'
            else
                letter = 'a-zA-Z\p{L}'  # Changed from RFC2822 to include unicode chars
            end
            digit          = '0-9'
            atext          = "[#{letter}#{digit}\!\#\$\%\&\'\*+\/\=\?\^\_\`\{\|\}\~\-]"
            dot_atom_text  = "#{atext}+([.]#{atext}*)+"
            dot_atom       = dot_atom_text
            no_ws_ctl      = '\x01-\x08\x11\x12\x14-\x1f\x7f'
            qtext          = "[^#{no_ws_ctl}\\x0d\\x22\\x5c]"  # Non-whitespace, non-control character except for \ and "
            text           = '[\x01-\x09\x11\x12\x14-\x7f]'
            quoted_pair    = "(\\x5c#{text})"
            qcontent       = "(?:#{qtext}|#{quoted_pair})"
            quoted_string  = "[\"]#{qcontent}+[\"]"
            atom           = "#{atext}+"
            word           = "(?:#{atom}|#{quoted_string})"
            obs_local_part = "#{word}([.]#{word})*"
            local_part     = "(?:#{dot_atom}|#{quoted_string}|#{obs_local_part})"
            dtext          = "[#{no_ws_ctl}\\x21-\\x5a\\x5e-\\x7e]"
            dcontent       = "(?:#{dtext}|#{quoted_pair})"
            domain_literal = "\\[#{dcontent}+\\]"
            obs_domain     = "#{atom}([.]#{atom})+"
            domain         = "(?:#{dot_atom}|#{domain_literal}|#{obs_domain})"
            addr_spec      = "#{local_part}\@#{domain}"
            pattern        = /\A#{addr_spec}\z/u

            return pattern
        end

        # 1.9: This requires a forced binary encoding in order to work.  This is
        # the old regex, though while not as thorough, does catch 'foo@a..b.com'
        # as invalid unlike the above.
        def valid_email_format
            qtext = '[^\\x22\\x5c\\x80-\\xff]'
            dtext = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
            atom = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' +
                '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
            quoted_pair = '\\x5c[\\x00-\\x7f]'
            domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
            quoted_string = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
            domain_ref = atom
            sub_domain = "(?:#{domain_ref}|#{domain_literal})"
            word = "(?:#{atom}|#{quoted_string})"
            domain = "#{sub_domain}(?:\\x2e#{sub_domain})+"
            local_part = "#{word}(?:\\x2e#{word})*"
            addr_spec = "#{local_part}\\x40#{domain}"
            pattern = /\A#{addr_spec.force_encoding('binary')}\z/

            return pattern
        end

        def initialize(model, name, options = {})
            options[:format] = valid_email_format
            super
        end

    end

end
