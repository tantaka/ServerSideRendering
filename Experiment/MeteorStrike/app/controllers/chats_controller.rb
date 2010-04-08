class ChatsController < ApplicationController
  layout 'chats', :only => 'index'
  skip_before_filter :verify_authenticity_token

  # GET /chats
  # GET /chats.xml
  def index
    @chats = Chat.find(:all).reverse
  end

  # GET /chats/1
  # GET /chats/1.xml
  def show
    @chat = Chat.find(params[:id])
  end

  # POST /chats
  # POST /chats.xml
  def create
    @chat = Chat.create(params[:chat])
    # create HTML string to show a message
    content = render_component_as_string :action => 'show', :id => @chat.id
    # create JS string to add a message on list
    javascript = render_to_string :update do |page|
      page.insert_html :top, 'chat-list', content
    end
    # push JS to clients listening 'shot_chat' channel
    Meteor.shoot 'shot_chat', javascript
    # nothing is rendered
    render :nothing => true
  end
end
