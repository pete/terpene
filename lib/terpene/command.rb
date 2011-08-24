require 'terpene'

module Terpene
  # This module contains the methods for the command line interface
  module Command

    class ParseError < StandardError; end

    # Given some pre-parsed args, makes the appropriate request to Nacreon to
    # run the specified command.
    def run_cmd(opts = {}, args = ['help'])
      # FIXME:  Simple but less than ideal:
      @opts = { :save_auth => true }.merge(opts)
      set_client!
      send(*args)
    end

    def usage o = $stdout
      d = Terpene::Client::DefaultOpts
      server_pretty = d[:server].map(&:to_s).join(':')

      o.puts "#{$0} [opts] command [command-args]",
        "(Options can also be specified via $TERPENEOPT)", <<EOUSAGE
The options:
  -a $file
    Uses the specified auth file instead of "#{d[:auth_file]}".
  -s $address
    Uses the server at $address instead of #{server_pretty}.
  -u $username
  -p $password
    Uses (and saves to #{d[:auth_file]}) the specified auth data.
  -E
    Encypt via HTTPS.
  -P
    Plaintext (i.e., no encryption, plain HTTP)
The commands are as follows, with optional arguments in brackets:
  show-apps
    Shows the apps owned by the logged-in user.
  show-app $app
    Shows only one app
  create-app $app
    Creates an application with the specified name.
  create-version $app [$version [$code.tgz]]
    Creates a new version of the named application.  If a .tgz file for the
    codebase is not specified, Terpene will attempt to create one, assuming
    that the current working directory is inside a git repository or the root
    of the project in a Subversion checkout.  If no version name is specified,
    git or SVN will be employed if applicable or the version will be named with
    the current date and time.
  deploy $app [$version]
    Deploys the named app; will use the specified version if provided or the
    latest version otherwise.
  kill $app [$version]
    Kills all instances of the specified version of the app, or, if the version
    is omitted, all instances.  Be careful!
EOUSAGE
    end

    def parse_args argv
      argv = (ENV['TERPENEOPT'].split(/[\t ]/) rescue []) + argv

      opts = argv.dup
      cmd = nil

      if(argv.first == 'help' ||
         %w(-h --help -help).any?(&argv.method(:include?)))
        return [{}, 'help']
      end

      parsed = {}

      while opt = opts.shift
        case opt
        when '-a'
          parsed[:auth_file] = ropt 'a', opts
        when '-s'
          server = ropt('s', opts).split(':', 2)
          server[1] &&= server[1].to_i
          server[1] ||= 443
          parsed[:server] = server
        when '-S'
          parsed[:ssl] = true
        when '-P'
          parsed[:ssl] = false
        else
          cmd = [opt.to_s.gsub('-', '_'), *opts]
          break
        end
      end

      if parsed[:ssl].nil?
        parsed[:ssl] = (parsed[:server][1] == 443 rescue false)
      end

      [parsed, cmd]
    end

    def help(*)
      usage
      exit
    end


    # Commands follow:
    def show_apps
      js_print c.apps
    end

    def show_app name
      js_print c.app(name)
    end

    def create_app name
      js_print c.create_app(name)
    end

    def create_version app, version = nil, tar_filename = nil
      tarball =
        if tar_filename
          File.read(tar_filename)
        else
          tar_up_wd
        end

      version ||= determine_version_name

      js_print c.create_version(app, version, tarball)
    end

    def deploy app, version = nil
      js_print c.deploy_app(app, version)
    end

    def kill app, version = nil
      js_print c.kill_app(app, version)
    end

    private

    def ropt name, opts
      opts.shift or raise(ParseError,
                          "Option \"-#{name}\" requires an argument.")
    end

    def js_print obj
      puts(JSON.pretty_unparse(obj))
    end

    def c
      @client
    end

    def set_client!
      @client = Terpene::Client.new @opts
      @client.authenticate
    end

    def tar_up_wd
      if git_repo?
        `git archive --format=tar HEAD | gzip`
      elsif svn_repo?
        raise "Oops:  SVN isn't implemented yet."
      else
        `tar -czf - .`
      end
    end

    def determine_version_name
      attempt =
        if git_repo?
          `git describe --always`.chomp
        else
          Time.now.strftime('%F-%H-%M-%S')
        end
      attempt.downcase.gsub(/[^-a-z0-9]/, '-')
    end

    def git_repo?
      File.directory?('.git') # FIXME:  Go up the filesystem until we find .git?
    end

    def svn_repo?
      File.directory?('.svn')
    end
  end
end
