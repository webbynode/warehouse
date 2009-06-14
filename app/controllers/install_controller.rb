require 'digest/sha1'
class InstallController < ApplicationController
  @@install_path = File.join(RAILS_ROOT, 'config', 'installs')
  skip_before_filter :check_for_repository
  before_filter :check_installed, :except => [:test_install, :settings]
  
  before_filter :admin_required, :only => :settings
  
  layout :choose_layout

  def index
    @repository = Repository.new(params[:repository])
    @user       = User.new(params[:user])
  end
  
  def install
    index
    unless @repository.valid? && @user.valid?
      render :action => 'index'
      return
    end

    Warehouse.write_config_file :domain => params[:domain]

    User.transaction do
      @repository.save!
      @user.save!
      @repository.grant :user => @user, :path => '/'
    end
    
    cookies[:login_token] = {:value => "#{@user.id};#{@user.token}", :expires => 1.year.from_now.utc, :domain => ".#{Warehouse.domain}", :path => '/'}
    
  rescue
    @message = $!.message
    logger.warn $!.message
    $!.backtrace.each { |b| logger.warn "> #{b}" }
    render :action => 'index'
  end

  def settings
    params[:settings]                     ||= {}
    params[:settings][:smtp_settings]     ||= {}
    params[:settings][:sendmail_settings] ||= {}
    return unless request.post?
    Warehouse.write_config_file params[:settings].merge(:domain => Warehouse.domain)
  end

  if RAILS_ENV == 'development'
    def test_install
      # @repository = Repository.new(:name => 'test', :path => '/foo/bar/baz')
      @repository = Repository.find(:first)
      render :action => 'install'
    end
  end
  
  protected
    def check_installed
      if installed? && session[:installing].nil?
        redirect_to root_path
      end
    end

    def choose_layout
      action_name == 'settings' ? 'application' : 'install'
    end
end
