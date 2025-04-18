require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path(Rails.root.join("config", "cron", "sidekiq_scheduler.yml"), __FILE__))
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  # Configure server-side Redis connection
  config.redis = { url: 'redis://sdnet-redis:6379/0' }
end

Sidekiq.configure_client do |config|
  # Configure client-side Redis connection
  config.redis = { url: 'redis://sdnet-redis:6379/0' }
end