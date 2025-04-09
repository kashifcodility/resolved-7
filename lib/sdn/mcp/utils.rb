require 'tmpdir'

module MCP
    module Utils
        module_function

        def tmpio
            fp = File.open("#{Dir::tmpdir}/#{rand}",
                File::RDWR|File::CREAT|File::EXCL, 0600)
            File.unlink(fp.path)
            fp.binmode
            fp.sync = true
            fp
        rescue Errno::EEXIST
            retry
        end

        def proc_name(foo)
            @orig_zero ||= $0
            @orig_argv ||= ARGV.join(' ')
            #$0 = "#{@orig_zero} #{foo} #{@orig_argv}"
            $0 = "#{foo}"
        end
    end
end
