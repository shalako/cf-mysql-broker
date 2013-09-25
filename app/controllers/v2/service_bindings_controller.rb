
class V2::ServiceBindingsController < V2::BaseController

  def update
    database_settings = AppSettings.database
    database_host = database_settings.host
    database_name = database_settings.singleton_database
    database_port = database_settings.port

    binding_guid = params.fetch(:id)
    creds = UserCreds.new(binding_guid)

    base_database_url = "mysql://#{creds.username}:#{creds.password}@#{database_host}:#{database_port}/#{database_name}"

    ActiveRecord::Base.connection.execute("CREATE USER '#{creds.username}' IDENTIFIED BY '#{creds.password}';")
    ActiveRecord::Base.connection.execute("GRANT ALL PRIVILEGES ON *.* TO '#{creds.username}';")
    ActiveRecord::Base.connection.execute("FLUSH PRIVILEGES;")

    render status: 201, :json => {
        'credentials' => {
            'hostname' => database_host,
            'name'     => database_name,
            'username' => creds.username,
            'password' => creds.password,
            'port'     => database_port,
            'jdbcUrl'  => "jdbc:#{base_database_url}",
            'uri'      => "#{base_database_url}?reconnect=true",
        }
    }.to_json
  end

  def destroy
    binding_guid = params.fetch(:id)
    creds = UserCreds.new(binding_guid)

    ActiveRecord::Base.connection.execute("DROP USER '#{creds.username}';")
    ActiveRecord::Base.connection.execute("FLUSH PRIVILEGES;")

    render status: 204, json: {}
  end
end