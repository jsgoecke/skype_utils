initialization do
  #Instantiate the object to track all active call sessions
  ::Active_skype_status = ActiveSkypeStatus.new
end

methods_for :global do
  #Used to fetch the status of a user
  #takes a username and returns a string containing status
  def skype_user_status?(username)
    if COMPONENTS.skype_utils['buddy_status_store'] == 'database'
      skype_user = SkypeUser.find_by_username username
      return skype_user.status
    else
      return ::Active_skype_status.get_status(username)
    end
  end
  
  #Used to return all statuses of the users
  #returns a hash containing all statuses
  def skype_user_statuses?
    if COMPONENTS.skype_utils['buddy_status_store'] == 'database'
      skype_statuses = Hash.new
      skype_users = SkypeUser.find(:all)
      skype_users.each do |user|
        if user.status != nil
          skype_statuses.merge!({ user.username => { :status => user.status } })
        end
      end
      return skype_statuses
    else
      return ::Active_skype_status.get_statuses
    end
  end
end

methods_for :dialplan do
  
  #Method that will fetch all available channel variables that may accompany a Skype call
  def fetch_skype_channel_variables
    
                                #A space-separated list of language identifiers
    skype_channel_variables = { :skype_languages => get_variable('CHANNEL(skype_languages)'),
                                #A user-provided string that can identify the 'topic'
                                #of the call; this is most commonly provided
                                #using a URL to dial a Skype name and specifying it
                                #as a query parameter, like this:
                                #skype:austin_powers?call&topic=secret_plans
                                :skype_topic => get_variable('CHANNEL(skype_topic)'),
                                #Similar to skype_topic
                                :skype_token => get_variable('CHANNEL(skype_token)'),
                                #'about' profile entry
                                :skype_about => get_variable('CHANNEL(skype_about)'),
                                #Birthday
                                :skype_birthday => get_variable('CHANNEL(skype_birthday)'),
                                #Gender
                                :skype_gender => get_variable('CHANNEL(skype_gender)'),
                                #Home page URL
                                :skype_homepage => get_variable('CHANNEL(skype_homepage)'),
                                #Home phone number
                                :skype_homephone => get_variable('CHANNEL(skype_homephone)'),
                                #Office phone number
                                :skype_officephone => get_variable('CHANNEL(skype_officephone)'),
                                #Mobile phone number
                                :skype_mobilephone => get_variable('CHANNEL(skype_mobilephone)'),
                                #City name
                                :skype_city => get_variable('CHANNEL(skype_city)'),
                                #State/Province name
                                :skype_province => get_variable('CHANNEL(skype_province)'),
                                #Country name
                                :skype_country => get_variable('CHANNEL(skype_country)') }
    
    return skype_channel_variables
  end
  
  #Method that translates between Asterisk Extension <-> Skype username
  #Accepts a hash with the following key / values:
  #  :translate => 'to_skype' or 'to_asterisk' are valid
  #  :value => either the extension or username to translate from
  def skype_user_translation(options)
    case options[:translate]
    when 'to_skype'
      user = SkypeUser.find(:first, :conditions => { :extension => options[:value] })
      return user.skype_user
    when 'to_asterisk'
      user = SkypeUser.find(:first, :conditions => { :skype_user => options[:value] })
      return user.extension
    end
  end
  
end

methods_for :events do
  
  #Used to get the Skype username out of the Skype buddy that comes back
  def get_skype_username(username)
    username = username.split('@')
    return username[1]
  end
  
  #Method that updates the status of a Skype user
  def skype_status_update(event)
    username = get_skype_username event.headers['Buddy']
    
    if COMPONENTS.skype_utils['buddy_status_store'] == 'database'
      skype_user = SkypeUser.find_by_username username
      if skype_user
        skype_user.status = event.headers['BuddyStatus']
        skype_user.save
      else
        if COMPONENTS.skype_utils['store_unknown_buddies']
          skype_user = SkypeUser.new
          skype_user.name = username
          skype_user.username = username
          skype_user.status = event.headers['BuddyStatus']
          skype_user.save
        end
      end
    end
    
    if COMPONENTS.skype_utils['buddy_status_store'] == 'memory' || COMPONENTS.skype_utils['buddy_status_store'] == 'both'
      ::Active_skype_status.update_status(username, event.headers['BuddyStatus'])
    end
  end
  
end

#Class for all of our Active call sessions
class ActiveSkypeStatus
  
  #Standard statuses
  # Online - user is online
  # Skype Me - user is available and asking to be 'Skyped'
  # Away - the user is away from their Skype client
  # Not Available - the user is not available for a call
  # Do Not Disturb - the user does not want to be disturbed
  # Offline (Voicemail Enabled) - the user is offline and has voicemail
  # Offline (Voicemail Disabled) - the user is offline and has no voicemail
  
  #Initialize the sessions hash of hashes and a Mutex to handle threadsafe updates
  def initialize
    @statuses = Hash.new
    @lock     = Mutex.new
  end
  
  #Read the sessions and return them based on the username key
  def get_status(username)
    return @statuses[username][:status]
  end
  
  #Method to return all sessions
  def get_statuses
    return @statuses
  end
  
  #Update the active session detail in a threadsafe way
  def update_status(username, status)
    @lock.synchronize do
      @statuses.merge!({ username => { :status => status } })
    end
  end
  
  #Delete the active session in a threadsafe way
  def delete_status(username)
    @lock.synchronize do
      @statuses.delete(username)
    end
  end
  
end