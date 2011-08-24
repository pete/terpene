require 'net/http'
require 'json'
require 'net/http/post/multipart'
require 'tempfile'
require 'terpene'

module Terpene
  # The Client class represents a single client for a Nacreon server.  The
  # typical life of a client is like this:
  #
  # Instantiate a client (see DefaultOpts):
  #    c = Terpene::Client.new :save_auth => true
  # Authenticate, using ~/.nacreon_auth (because we told it to do that
  # above):
  #    c.authenticate # Loads auth data from a file, since we told it to.
  # Create a basic rack application, now that we're authenticated:
  #    c.create_app 'super-app'
  # Ask the server what the app looks like:
  #    p c.apps['super-app']
  class Client
    # The default set of options, which may be passed at initialization
    # time or altered after initialization through Terpene::Client#opts .
    DefaultOpts = {
      # Should auth tokens be saved to or read from a file?
      :save_auth => false,
      # The location of the auth file.  The file is JSON-formatted.  It's
      # also cleartext, so use this option (and :save_auth) with care.
      :auth_file => "#{ENV['HOME']}/.nacreon_auth",
      # The connection information for the server, as [host, port].
      :server => ['localhost', 4999],
      # Use HTTPS when talking to the server?
      :ssl => false,
      # Providing an object that responds to :'<<' will get you some
      # logging.
      :debug_out => nil,
    }

    attr_accessor :opts, :latest_response, :username, :password

    # Creates a client, optionally with a list of options, as a hash.
    # Supported options and their defaults are found in
    # Terpene::Client::DefaultOpts .
    def initialize opts = {}
      self.opts = DefaultOpts.merge opts
    end

    # Attempts to authenticate a user based on username and password, which
    # may be passed in, or may be loaded from opts[:auth_file] if
    # opts[:save_auth] is true.  If the options are passed in and
    # opts[:save_auth] is true, then they authorization will be saved.
    def authenticate user = nil, pass = nil
      if user.nil? || pass.nil?
        if opts[:save_auth]
          user, pass = load_auth
        end
      else
        save_auth(user, pass) if opts[:save_auth]
      end

      # should at some point actually contact the server to verify, we
      # assume it's fine for now
      return nil if(user.nil? || pass.nil?)
      self.username, self.password = user, pass
      true
    end

    # Creates an application with the specified name and template.
    def create_app name
      data = {
        'name' => name,
        'owner_name' => username,
      }.to_json

      try_json post('/app', data)
    end

    def update_app name, opts = {}
      try_json put("/app/#{name}", data)
    end

    # Deletes the named application.
    def delete_app name
      try_json delete("/app/#{name}")
    end

    # Deletes all of the apps you can.  Be careful!
    def delete_all_apps
      apps.map { |a| delete_app a['name'] }
    end

    # Returns a list of applications deployed to Nacreon and information
    # about them.
    def apps
      try_json get('/app')
    end

    # Returns information about the named application.
    def app name
      try_json get("/app/#{name}")
    end

    # Deploys the named app with the named version.  If no version is
    # specified, the latest version will be deployed.
    def deploy_app name, version = nil
      v = version ? "&version=#{version}" : ''
      try_json post("/app/#{name}?mode=deploy#{v}")
    end

    def cleanup_app name
      try_json post("/app/#{name}?mode=cleanup")
    end

    def kill_app name, version = nil
      v = version ? "&version=#{version}" : ''
      try_json post("/app/#{name}?mode=kill#{v}")
    end

    def versions app_name
      try_json get("/app/#{app_name}/version")
    end

    def version app_name, version_name
      try_json get("/app/#{name}/version/#{name}")
    end

    def create_version app_name, version_name, tarball
      try_json put("/app/#{app_name}/version/#{version_name}", tarball)
    end

    # Creates a user with the specified login, password, and an optional
    # level, which must be :user (the default) or :admin.
    def create_user username, password, ssh_key
      data = {
        'ssh_key' => ssh_key,
        'name' => username,
        'password' => password,
      }
      try_json post("/user", data.to_json)
    end

    # Deletes a user.
    def delete_user name
      try_json delete("/user/#{name}")
    end

    # A list of users and associated info.
    def users
      try_json get('/user')
    end

    # private

    # Returns [username, password] or nil.
    def load_auth
      begin
        authdata = JSON.parse(File.read(opts[:auth_file]))
        [authdata['username'], authdata['password']]
      rescue
      end
    end

    def save_auth username, pass
      js = JSON.pretty_unparse('username' => username, 'password' => pass)

      begin
        File.open(opts[:auth_file], 'w') { |f| f.puts js }
      rescue
        return false
      end

      true
    end

    def http req
      h = Net::HTTP.new(*opts[:server])
      h.use_ssl = opts[:ssl]
      h.start { |http|
        req.basic_auth username, password
        r = http.request req
        self.latest_response = r

        case r.code.to_i
        when 100..199
          r # I don't anticipate getting this from Nacreon.
        when 200..299
          r
        when 300..399
          r # TODO:  Handle redirects
        when 401
          raise Terpene::AuthenticationError,
          "Authorization data invalid."
        when 400, 402..499
          r # TODO:  These need handling internally
        when 500..599
          r # TODO:  Need to account for problems in Nacreon.
        end
      }
    end

    # These, so far, are the only methods Nacreon uses:

    def get path
      http Net::HTTP::Get.new(path)
    end

    def delete path
      http Net::HTTP::Delete.new(path)
    end

    def post path, body = nil
      r = Net::HTTP::Post.new path
      r.body = body
      http r
    end

    def put path, body = nil
      r = Net::HTTP::Put.new path
      r.body = body
      http r
    end

    def try_json req
      req = req.body if req.respond_to? :body
      begin
        JSON.parse req.to_s
      rescue
      end
    end
  end
end
