class ThorHelpers::Redis < ThorHelpers::Base
  def initialize(options={})
  end

  def insert_config(config, hash)
    set_params_to_redis(config, hash)
  end

  def update_project

  end

  private

  def set_params_to_redis(params, random_hash)
    Sidekiq.redis { |connection| connection.set(random_hash, encrypt_params(params, random_hash)) }
  end

  def encrypt_params(params, random_hash)
    crypt = ActiveSupport::MessageEncryptor.new(random_hash)
    crypt.encrypt_and_sign(params.to_json)
  end
end
