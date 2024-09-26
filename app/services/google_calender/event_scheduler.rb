require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'

module GoogleCalender
  class EventScheduler
    attr_accessor :event, :user, :client

    CALENDAR_ID = 'primary'

    def initialize(user, event)
      @user = user
      @event = event
      @client = build_client
      @service = Google::Apis::CalendarV3::CalendarService.new # Servisi burada oluşturun
    end



    # Event kaydetme
    # Event kaydetme
    def register_event
      calendar_event = Google::Apis::CalendarV3::Event.new(
        summary: event.summary,
        description: event.description,
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: event.start_time.to_datetime.rfc3339,
          time_zone: 'America/New_York'
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: event.end_time.to_datetime.rfc3339,
          time_zone: 'America/New_York'
        ),
        attendees: [
          Google::Apis::CalendarV3::EventAttendee.new(
            email: user.email
          )
        ]
      )

      begin
        regenerate_token_if_expired?

        result = service.insert_event(CALENDAR_ID, calendar_event, send_notifications: true)
        event.update!(gc_event_id: result.id, gc_link: result.html_link)
      rescue StandardError => e
        puts "Event kaydedilirken hata oluştu: #{e.message}"
      end
    end

    # Event güncelleme
    def update_event
      calendar_event = client.get_event(CALENDAR_ID, event.gc_event_id)
      return if calendar_event.nil? || calendar_event.id.nil?

      # Güncellemeleri yap
      calendar_event.summary = event.summary
      #calendar_event.location = event.location
      calendar_event.description = event.description
      calendar_event.start = Google::Apis::CalendarV3::EventDateTime.new(
        date_time: event.start_at.to_datetime.rfc3339,
        time_zone: 'America/New_York'
      )
      calendar_event.end = Google::Apis::CalendarV3::EventDateTime.new(
        date_time: event.end_at.to_datetime.rfc3339,
        time_zone: 'America/New_York'
      )

      result = client.update_event(CALENDAR_ID, calendar_event.id, calendar_event)
      puts "Event güncellendi: #{result.updated}"
    rescue Google::Apis::AuthorizationError => e
      puts "Yetkilendirme hatası: #{e.message}. Token'ı yenilemeye çalışıyoruz..."
      regenerate_token_if_expired?(client)
      # Yenilemeden sonra tekrar güncellemeyi deneyelim
      update_event
    rescue StandardError => e
      puts "Event güncellenirken hata oluştu: #{e.message}"
    end


    # Event silme
    def delete_event
      client.delete_event(CALENDAR_ID, event.gc_event_id)
    rescue StandardError => e
      puts "Event silinirken hata oluştu: #{event.id}, hata: #{e.message}"
    end

    private

    # Client oluşturma
    def build_client
      return unless user.present? && user.access_token.present? && user.refresh_token.present?

      client = Google::Apis::CalendarV3::CalendarService.new
      secrets = Google::APIClient::ClientSecrets.new({
                                                       'web' => {
                                                         'access_token' => user.access_token,
                                                         'refresh_token' => user.refresh_token,
                                                         'client_id' => Rails.application.credentials.dig(:google_oauth2, :client_id),
                                                         'client_secret' => Rails.application.credentials.dig(:google_oauth2, :client_secret)

                                                       }

                                                     })

      client.authorization = secrets.to_authorization
      regenerate_token_if_expired?(client)

      client
    end

    # Token süresini kontrol edip yeniler
    def regenerate_token_if_expired?(client)
      return unless user.token_expired?

      begin
        client.authorization.refresh!
        user.update!(
          access_token: client.authorization.access_token,
          refresh_token: client.authorization.refresh_token,
          token_expires_at: Time.at(client.authorization.expires_at).to_datetime
        )
      rescue StandardError => e
        puts "Token yenilenirken hata oluştu: #{e.message}"
      end
    end
  end
end
