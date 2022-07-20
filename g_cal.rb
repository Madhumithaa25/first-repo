{
  title: "Google Calendar",

  connection: {
   fields: [
     {
      name: "client_id",
        hint: "Find client ID " \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false
      },
      {
        name: "client_secret",
        hint: "Find client secret " \
          "<a href='https://console.cloud.google.com/apis/credentials' " \
          "target='_blank'>here</a>",
        optional: false,
        control_type: "password"
      },
     {
       name: "calendar_id",
       label: "Calendar Id",
       hint: "Enter your email id",
       optional: false,
     },
     {
       name: "event_id",
       label: "Event Id",
       hint: "Enter event id if you want to update an event"
     }
    ],

    authorization: {
      type: "oauth2",

      authorization_url: lambda do |connection|
        scopes = [
          "https://www.googleapis.com/auth/calendar",
          "https://www.googleapis.com/auth/calendar.readonly"
        ].join(" ")

        "https://accounts.google.com/o/oauth2/auth?client_id=" \
        "#{connection['client_id']}&response_type=code&scope=#{scopes}" \
        "&access_type=offline&include_granted_scopes=true&prompt=consent"
      end,

      acquire: lambda do |connection, auth_code, redirect_uri|
        response = post("https://accounts.google.com/o/oauth2/token").
                     payload(client_id: connection["client_id"],
                             client_secret: connection["client_secret"],
                             grant_type: "authorization_code",
                             code: auth_code,
                             redirect_uri: redirect_uri).
                     request_format_www_form_urlencoded
        [response, nil, nil]
      end,

      refresh: lambda do |connection, refresh_token|
        post("https://accounts.google.com/o/oauth2/token").
          payload(client_id: connection["client_id"],
                  client_secret: connection["client_secret"],
                  grant_type: "refresh_token",
                  refresh_token: refresh_token).
          request_format_www_form_urlencoded
      end,

      refresh_on: [401],

      detect_on: [/"errors"\:\s*\[/],

      apply: lambda do |_connection, access_token|
        headers("Authorization" => "Bearer #{access_token}")
      end
    },

    base_uri: lambda do |_connection|
      "https://www.googleapis.com"
    end
  },

  test: lambda do |_connection|
    get("/calendar/v3/users/me/settings?maxResults=1")
  end,

    actions: {
    get_events: {

    execute: lambda do |_connection, input, _input_schema, _output_schema|
      get("/calendar/v3/calendars/#{_connection['calendar_id']}/events").
              params(singleEvents: true,
                     orderBy: "startTime",
                     maxResults: 50)

    end,
    } ,

   add_event: {
     execute: lambda do |_connection, input, _input_schema, _output_schema|
       post("/calendar/v3/calendars/#{_connection['calendar_id']}/events").payload(start: { dateTime: "2022-07-08T12:30:00+05:30"}, end: { dateTime: "2022-07-08T13:30:00+05:30"}, summary: "Testing API", visibility: "public", transparency: "transparent", description: "This event is created to test SDK connector - G Calendar", attendees: [ {displayname: "Madhu", email: _connection['calendar_id']}  ] )
   end,
   },

  update_event: {
    execute: lambda do |_connection, input, _input_schema, _output_schema|
      if _connection['event_id'].length!=0
        patch("calendar/v3/calendars/#{_connection['calendar_id']}/events/#{_connection['event_id']}").payload(start: { dateTime: "2022-07-08T13:30:00+05:30"}, end: { dateTime: "2022-07-08T14:30:00+05:30"}, summary: "Testing Patch API call")
      else
      end
    end,
  },
  update_first_event: {
    execute: lambda do |_connection, input, _input_schema, _output_schema|
    first_event = get("/calendar/v3/calendars/#{_connection['calendar_id']}/events").
              params(singleEvents: true,
                      timeMax: "2022-07-08T00:00:00+05:30:00",
                      timeMin: "2022-07-01T00:00:00+05:30:00",
                     orderBy: "startTime",
                     maxResults: 50)['items'][0]
   first_event_id = first_event['id']
   patch("calendar/v3/calendars/#{_connection['calendar_id']}/events/#{first_event_id}").payload( summary: "This is the first event received and it has beeen updated")
   end,


  }

  },

### NOT WORKING
# triggers: {
#     watch_events: {
#       description: "It will watch for changes in event resources",
#       help: "Trigger will pick up events that has been changed",
#
#       webhook_watch: lambda do |webhook_url, _connection, input|
#         post("/calendar/v3/calendars/#{_connection['calendar_id']}/events/watch", id: "primary", type: "web_hook", address: webhook_url)
#       end,
#     }
# }


}
