##
## "Common" Rakefile tasks -- means this will be included in *all* invocations,
## top-level and in-app, repo-wide.
##
## Needs to adhere to the established "dependency loading" idiom to keep this
## file light and fast.
##

task :default do
    if IS_WINDOWS
        puts "Sorry Windows blows, you'll have to run ``rake -T'' on your own."
        exit(1)
    end

    Kernel.exec("#{$0}", '-T')
end
