require 'create_git/create_svn'
class CreateSvnController < ApplicationController
  unloadable

  before_filter :find_project, :only => [:new, :create]
  before_filter :check_create_permission
  before_filter :check_settings

  def new

    @repo_path_base = Setting.plugin_redmine_create_git['svn_repo_path']
    unless @repo_path_base.nil? or @repo_path_base.empty?
      @repo_path_base += '/' unless @repo_path_base[-1, 1]=='/'
      @repo_path_base += @project.identifier
    end

  end


  def create

    @identifier = params[:repo_identifier]
    @is_default = params[:is_default]
    @repository = nil
    begin
      @repository = SvnCreator::create_svn(@project, @identifier, @is_default)
      if @repository and @repository.save
        redirect_to :controller => 'repositories', :action => 'show', :id => @project, :repository_id => @repository.identifier_param
      else
        render :action => 'new'
      end
    rescue Exception => e
      flash[:error] = e.message
      render :action => 'new'
    end
  end

  private

  def find_project
    @project = Project.find_by_identifier(params[:project_id])
  end

  def check_settings
    repo_path = Setting.plugin_redmine_create_git['svn_repo_path']
    return flash[:error] = I18n.t('errors.repo_path_undefined') if repo_path.nil? or repo_path.empty?
    return flash[:error] = I18n.t('repo_path_doesnt_exist', {:path => repo_path}) unless File.exist?(repo_path)
    return flash[:error] = I18n.t('repo_path_not_writable', {:path => repo_path}) unless (File.exist?(repo_path) and File.stat(repo_path).writable_real?)
  end

  def check_create_permission
    authorize('repositories', 'new')
  end

end
