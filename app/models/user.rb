class User < ApplicationRecord
  has_many :calendar_events, dependent: :destroy
  # Kullanıcının token süresinin dolup dolmadığını kontrol eden metot
  def token_expired?
    # token_expires_at sütununda token'ın süresi tutuluyor
    token_expires_at < Time.current
  end
end
