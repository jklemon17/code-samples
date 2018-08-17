# This feature was built to automatically mark conversations in which tutors might be trying to take students 
# off the platform, so that admins could take action. It involved flagging the content and displaying the flags 
# in a conversations index, as well as giving admins the ability to sort and filter the conversations and remove
# flags from conversations. The following are pieces of the code that I wrote to accomplish this.

#app/controllers/content_flags_controller.rb
class ContentFlagsController < ApplicationController
  def destroy
    @content_flag = ContentFlag.find(params[:id])
    @content_flag.destroy
    redirect_back fallback_location: root_path, notice: "Flag removed"
  end
end

#app/controllers/conversations_controller.rb
...
def index
  unless current_user
    redirect_to '/login'
  end

  handle_filter_sort
end

...

private
 def handle_filter_sort
  @order_reversed = params[:oldest] == 'true'
  if @order_reversed
    @conversations = current_user.conversations.reverse
  else
    @conversations = current_user.conversations
  end
   @with_alerts = params[:withalerts] == 'true'
  if @with_alerts
    @conversations = @conversations.select{|conversation| conversation.flagged?}
  end
end

#app/models/conversation.rb
...
def self.most_recent_active
  @recent = self.all_active.sort_by {|conversation| conversation.updated_at}
  @recent =  @recent.reverse!
end

...

def flagged?
  ContentFlag.find_by(conversation_id: self.id) ? true : false
end

#app/models/message.rb
after_save  :enforce_message_content_policy,
            :set_conversation_updated_at
            
...

def has_phone?
    msg = self.content
    @numbers = msg.gsub(/[^0-9]/, "")
    if @numbers.length == 10 or @numbers.length  == 7
      true
    else
      false
    end
  end

  def has_email?
    msg = self.content
    if msg.include?("@")
      true
    else
      false
    end
  end

  def blacklist_words
    [
      'cash',
      'pay'
    ]
  end

  def has_blacklist_keyword?
    msg = self.content.downcase
    blacklist_words.each do |word|
      return true if msg.include?(word)
    end
    return false
  end

  def should_flag?
    return true if has_phone? ||
                   has_email? ||
                   has_blacklist_keyword?
  end

  def enforce_message_content_policy
    if should_flag?
      unless ContentFlag.find_by(conversation_id: self.conversation_id)
          ContentFlag.create(
            user_id: self.coordinator_id,
            tutor_id: self.tutor_id,
            offending_party_id: self.sent_by,
            tutoring_session_id: self.tutoring_session_id,
            message_id: self.id,
            conversation_id: self.conversation.id
          )
      end
    end
  end

  def set_conversation_updated_at
    self.conversation.updated_at = self.created_at
    self.conversation.save
  end
  
#app/views/conversations/_conversation_li.html.erb
...
<%= render 'conversations/flag_status', :conversation => conversation %>
...
  
#app/views/conversations/_flag_status.html.erb
<% if current_user.type == "Administrator" %>
  <div>
    <% if conversation.flagged? %>
      <h4>
        <%= button_to content_flag_path(ContentFlag.find_by(conversation_id: conversation.id)), method: :delete, data: {confirm: "Remove this alert?"}, class: 'btn btn-xs btn-danger' do %>
          ALERT <i class="fa fa-times"></i>
        <% end %>
      </h4>
    <% else %>
      <span class="btn btn-success btn-xs"> GOOD </span>
    <% end %>
  </div>
<% end %>

#app/views/conversations/_sort_filter.html.erb
<div class="container-fluid gray-bg hidden-xs">
  <div class="col-md-10 col-md-offset-1 text-center">
    <div class="row smallpad">
      <div class="col-md-4">
        <a class="btn btn-default" href="/conversations?<%= "&oldest=true" unless @order_reversed %><%= "&withalerts=true" if @with_alerts %>"><i class="fa fa-arrow-down"></i> Reorder by <%= @order_reversed ? "Newest" : "Oldest" %> First</a>
      </div>
      <div class="col-md-4">
      </div>
      <div class="col-md-4">
        <label class="alerts-toggle">
          <a class="btn btn-default" href="/conversations?<%= "&oldest=true" if @order_reversed %><%= "&withalerts=true" unless @with_alerts %>">
            <%= check_box_tag "nameforid", "value", @with_alerts, class:"hidden-checkbox" %>
            <span class="messages-filter gray-bg"></span>
            Alerts Only
          </a>
        </label>
      </div>
    </div>
   </div>
</div>

#app/views/conversations/index.html.erb
...
<% if current_user.type == 'Administrator' %>
  <%= render 'sort_filter' %>
<% end %>
...

#config/routes.rb
...
resources :content_flags, :only => [:destroy]
...

#db/migrate/20180724204546_add_conversation_id_to_content_flags.rb
class AddConversationIdToContentFlags < ActiveRecord::Migration[5.1]
  def change
    add_column :content_flags, :conversation_id, :integer
  end
end
