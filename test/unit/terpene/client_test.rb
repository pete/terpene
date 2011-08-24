require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'test_helper'))
class Terpene::ClientTest < Test::Unit::TestCase
  def test_initialize_basic
    # does it smoke like a client?
    Terpene::Client.new
  end

  def test_authenticate_with_u_p_saving
    c = Terpene::Client.new(:save_auth => true)
    c.expects(:save_auth).with('user', 'pass')
    c.authenticate('user', 'pass')
    assert_equal(c.username, 'user', 'should have the provided username')
    assert_equal(c.password, 'pass', 'should have the provided password')
  end

  def test_authenticate_without_u_p_saving
    c = Terpene::Client.new(:save_auth => false)
    c.expects(:save_auth).never.with('user', 'pass')
    c.authenticate('user', 'pass')
    assert_equal(c.username, 'user', 'should have the provided username')
    assert_equal(c.password, 'pass', 'should have the provided password')
  end

  def test_authenticate_with_u_p_loading
    c = Terpene::Client.new(:save_auth => true)
    c.expects(:load_auth).returns(['user', 'pass'])
    c.authenticate
    assert_equal(c.username, 'user', 'should have the provided username')
    assert_equal(c.password, 'pass', 'should have the provided password')
  end

  def test_authenticate_without_u_p
    c = Terpene::Client.new(:save_auth => false)
    c.expects(:load_auth).never
    c.authenticate
    assert_equal(c.username, nil, 'should have the provided username')
    assert_equal(c.password, nil, 'should have the provided password')
  end

  def test_opts
    c = Terpene::Client.new(:lame_key => true)
    assert_equal(true, c.opts[:lame_key])
  end

  def test_latest_response
    c = Terpene::Client.new
    assert_equal(nil, c.latest_response)
  end

  def test_username
    c = Terpene::Client.new
    c.username = 'foo'
    assert_equal('foo', c.username)
  end

  def test_password
    c = Terpene::Client.new
    c.password = 'foo'
    assert_equal('foo', c.password)
  end

  def test_create_app
    c = Terpene::Client.new
    c.expects(:post).with('/app', { 'name' => 'app name', 'owner_name' => 'user' }.to_json)
    c.expects(:try_json)
    c.authenticate('user', 'pass')
    c.create_app('app name')
  end

  def test_update_app
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:put).with('/app/app name', {'an option' => true }.to_json)
    c.update_app('app name', {'an option' => true })
  end

  def test_delete_app
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:delete).with('/app/app name')
    c.delete_app('app name')
  end

  def test_delete_all_apps
    c = Terpene::Client.new
    c.expects(:apps).returns([ {'name' => 'app name'} ])
    c.expects(:delete_app).with('app name')
    c.delete_all_apps
  end

  def test_apps
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:get).with('/app')
    c.apps
  end

  def test_app
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:get).with('/app/app name')
    c.app('app name')
  end

  def test_deploy_app_latest
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/app/app name?deploy-latest')
    c.deploy_app('app name')
  end

  def test_deploy_app_with_version
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/app/app name?deploy-version=foo')
    c.deploy_app('app name', 'foo')
  end

  def test_cleanup_app
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/app/app name?cleanup')
    c.cleanup_app('app name')
  end

  def test_kill_app
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/app/app name?kill-all')
    c.kill_app('app name')
  end

  def test_versions
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:get).with('/app/app name/version')
    c.versions('app name')
  end

  def test_version
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:get).with('/app/app name/version/foo')
    c.version('app name', 'foo')
  end

  def test_create_user_default
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/user', {'ssh_key' => 'key', 'name' => 'user', 'password' => 'pass'}.to_json)
    c.create_user('user', 'pass', 'key')
  end

  def test_create_user_admin
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/user', {'ssh_key' => 'key', 'name' => 'user', 'password' => 'pass', 'level' => :admin}.to_json)
    c.create_user('user', 'pass', 'key')
  end

  def test_create_user_user
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:post).with('/user', {'ssh_key' => 'key', 'name' => 'user', 'password' => 'pass', 'level' => :user}.to_json)
    c.create_user('user', 'pass', 'key')
  end

  def test_delete_user
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:delete).with('/user/user')
    c.delete_user('user')
  end

  def test_users
    c = Terpene::Client.new
    c.expects(:try_json)
    c.expects(:get).with('/user')
    c.users
  end
end
