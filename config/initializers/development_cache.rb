if Rails.env.development?
  # Force enable caching in development
  Rails.application.configure do
    config.action_controller.perform_caching = true
    config.cache_store = :memory_store
  end

  # Initialize the cache store
  Rails.cache = ActiveSupport::Cache::MemoryStore.new(size: 64.megabytes)
  
  # Clear the cache on startup
  Rails.cache.clear
end
