class GoogleCalendarService
  include HTTParty
  base_uri 'https://www.googleapis.com/calendar/v3'

  def initialize(user)
    @user = user
    @headers = {
      'Authorization' => "Bearer #{@user.access_token}",
      'Content-Type' => 'application/json'
    }
  end

  def list_events
    refresh_token # Access token'ı yenile
    response = self.class.get('/calendars/primary/events', headers: @headers)

    if response.success?
      events = JSON.parse(response.body)['items']

      events.each do |event|
        CalendarEvent.find_or_create_by(event_id: event['id'], user: @user) do |calendar_event|
          calendar_event.update(
            calendar_id: event['organizer']['email'],
            summary: event['summary'],
            description: event['description'],
            start_time: event['start']['dateTime'],
            end_time: event['end']['dateTime'],
            hangout_link: event['hangoutLink']
          )
        end
      end
    else
      # Hata yönetimi
      Rails.logger.error("Failed to fetch events: #{response.code} - #{response.body}")
    end
  end

  def refresh_token
    return unless @user.refresh_token && @user.token_expires_at < Time.now

    # Yeni access token'ı al
    client = OAuth2::Client.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], site: 'https://accounts.google.com')
    token = OAuth2::AccessToken.new(client, @user.access_token, refresh_token: @user.refresh_token, expires_at: @user.token_expires_at.to_i)

    new_token = token.refresh! # Doğru metodu çağırıyoruz
    @user.update(
      access_token: new_token.token,
      token_expires_at: Time.at(new_token.expires_at)
    )
  rescue OAuth2::Error => e
    Rails.logger.error("Failed to refresh token: #{e.message}")
    # Hata yönetimi (kullanıcıyı bilgilendirmek gibi)
  end
end
