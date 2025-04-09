
namespace :clear do

    task :gems do
        gemlist = `gem list --no-versions`.split("\n").compact.join(" ")
        puts `gem uninstall #{gemlist} -aIx`
    end

    task :cache do
        cache_dir = 'tmp/cache'
        next unless File.exists? cache_dir
        FileUtils.rm_rf cache_dir
    end

end
