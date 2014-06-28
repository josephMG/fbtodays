class FbtodaysController < ApplicationController
  def index
    puts "****************\n#{session[:access_token]}\n*****************"
#    FbGraph2.debug!
    begin
      @me = get_me
    rescue
      redirect_to "/login" and return 
    end
  end

  def callback
    @client=client
    @client.authorization_code = params[:code]
    session[:access_token] = @client.access_token! :client_auth_body # => Rack::OAuth2::AccessToken
    puts "===========\n#{session[:access_token]}\n====================="
    redirect_to root_path and return
  end
  def show
    if session[:access_token].nil?
      redirect_to "/login" and return
    end
    now=DateTime.now
    midnight=DateTime.new(now.year, now.month, now.day, 0, 0, 0, "+08:00")
    until_time=now.to_time.to_i
    midnight_time=midnight.to_time.to_i
    me=get_me
    @feeds=me.home
#    mylog.info @feeds.methods
#    @feeds.select! {|feed| feed.type=="status"}
    @feeds.each do |feed|
      if feed.status_type.nil?
        origin=get_origin(feed.id)
        feed.link=feed.actions.first.link if (origin.nil? && feed.actions.present?)
        feed.id=(origin.nil?)? feed.id : origin.id
      end
      count_info= like_comment_share_count(feed.id)
      feed = add_attr feed,count_info
    end
    render :layout => false
  end
  def login
    #    @oauth=Koala::Facebook::OAuth.new(ENV['fb_app'], ENV['fb_secret'],ENV['site_url'])
    #    redirect_to @oauth.url_for_oauth_code
    @client=client
    redirect_to @client.authorization_uri(
      :scope => [:email, :read_stream]
    )

  end
  private
  def get_all(graph,iSince = nil,iUntil = nil)
    @my_logger.info "****************************"
    @my_logger.info "**********get_all***********"
    @my_logger.info "****************************"
    @my_logger.info "************since => #{iSince}, until => #{iUntil}"
    @my_logger.info "************since => #{Time.at(iSince)}, until => #{Time.at(iUntil)}"
    now=DateTime.now
    midnight=DateTime.new(now.year, now.month, now.day, 0, 0, 0, "+08:00")
    until_time=(iUntil.nil?) ? now.to_time.to_i : iUntil
    midnight_time=(iSince.nil?) ? midnight.to_time.to_i : iSince
    param={"since"=>midnight_time.to_s,"until"=>until_time.to_s}
    @my_logger.info "************param => #{param}"
    result = graph.get_object("me/home",param)
    feeds=result
    return if feeds.empty?
    t2=feeds.next_page_params[1]["until"]
    @my_logger.info "************(since)midnight_time => #{midnight_time}, (until)t2 => #{t2.to_i}"
    @my_logger.info "************(since)midnight_time => #{Time.at(midnight_time)}, (until)t2 => #{Time.at(t2.to_i)}"
    until t2.to_i<midnight_time do
      param=result.next_page_params[1]
      param["since"]=midnight_time.to_s
      #result = graph.get_object("me/home",param)
      result=graph.get_page(result.next_page_params)
      if result.empty?
        break
      end
      until_time=t2.to_i-1
      feeds+=result
      t2=result.next_page_params[1]["until"]
      @my_logger.info "************(since)midnight_time => #{Time.at(midnight_time)}, (until)t2 => #{Time.at(t2.to_i)}"
    end
    parse_data feeds
    @my_logger.info "****************************"
    @my_logger.info "************feeds.length => #{feeds.length}"
    @my_logger.info "****************************"
  end
  def each_recursive(key,value)
    if value.class==Hash
      value.each do |k,v|
        each_recursive(key+"[\"#{k}\"]",v)
      end
    elsif value.class==Array
      value.each_with_index do |v,index|
        each_recursive(key+"[\"#{index}\"]",v)
      end
    else
      @my_logger.info "#{key} (lenght: ): #{value}"
    end 
  end
  def get_origin id
    post_id=id.split('_').last
    origin=get_node FbGraph2::Post.new(post_id)
    origin
  end
  def get_node(node)
    begin
      node=node.authenticate session[:access_token]
      node.fetch
    rescue
      nil
    end
  end
  def client
    client=FbGraph2::Auth.new(ENV['fb_app'], ENV['fb_secret'])
    client.authorization_endpoint="/oauth/authorize"
    #client = fb_auth.client
    client.redirect_uri = ENV["site_url"] + "fbtodays/callback"
    client
  end
  def mylog
    @my_logger ||= Logger.new("#{Rails.root}/log/my.log")
    @my_logger
  end
  def like_comment_share_count post_id
    fql="SELECT like_info.like_count, comment_info.comment_count, share_count 
         FROM stream 
         WHERE post_id = '#{post_id}'"

    rest = Koala::Facebook::API.new(session[:access_token])
    ret=rest.fql_query(fql)
    ret
  end
  def add_attr feed, count_info
    feed.instance_eval do
      def share_count
        instance_variable_get("@share_count")
      end        
      def share_count=(val) 
        instance_variable_set("@share_count",val)
      end
      def comment_count
        instance_variable_get("@comment_count")
      end        
      def comment_count=(val) 
        instance_variable_set("@comment_count",val)
      end
      def like_count
        instance_variable_get("@like_count")
      end        
      def like_count=(val) 
        instance_variable_set("@like_count",val)
      end
    end
    feed.like_count= feed.comment_count= feed.share_count=0
    if !count_info.empty?
      count_info=count_info[0]
      feed.like_count=count_info["like_info"]["like_count"]
      feed.comment_count=count_info["comment_info"]["comment_count"]
      feed.share_count=count_info["share_count"]
    end
    feed
  end
  def get_me
    FbGraph2::User.me(session[:access_token]).fetch # => FbGraph::User
  end
end
