# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
class MessageThread
  attr_reader :recipients, :sender
  include Enumerable

  def initialize(options)
    @subject    = options[:subject]
    @body       = options[:body]
    @sender     = options[:sender]
    @recipient_logins = options[:recipients]
    @recipients = extract_recipients(options[:recipients])
    Rails.logger.debug("MessageThread for #{@recipients.join(',')}")
  end

  def each
    messages.each{|m| yield m}
  end

  def extract_recipients(recipient_string)
    recipient_string.split(/[,\s\.]/).map(&:strip)
  end

  def messages
    @messages ||= initialize_messages
  end

  def size
    messages.size
  end

  def title
    "#{size} " + ((size == 1) ? 'message' : 'messages')
  end

  # Returns a message object, used in views etc
  def message
    Message.new(:sender => @sender, :subject => @subject, :body => @body, :recipient_logins => @recipient_logins)
  end

  def validated_message
    msg = message
    msg.valid?
    if msg.recipients.blank?
      msg.errors.add(:recipients, "can't be blank")
    end
    msg
  end

  def save!
    messages.each do |msg|
      SendMessage.call(sender: msg.sender, subject: msg.subject, body: msg.body, recipient: msg.recipient)
    end
  end

  protected

  def initialize_messages
    recipients.inject([]) do |result, recipient_name|
      result << Message.new(:sender => @sender, :subject => @subject, :body => @body, :recipient => User.find_by_login(recipient_name))
    end
  end
end
