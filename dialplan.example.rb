#Example of dialing an Asterisk extension and then converting to a 
#Skype user to dial out over the Skype for Asterisk channel
outbound_extension {
  
  skype_user = skype_user_translation({ :translate => 'to_skype', :value => extension })
  if skype_user
    dial "Skype/" + skype_user
  end
  
}

#Example of an inbound call from the Skype network that shows the Skype 
#channel variables available, then translates to an Asterisk extension
#based on the Skype username
inbound_skype_call {
  
  skype_channel_variables = fetch_skype_channel_variables
  ahn_log.skype.info skype_channel_variables.inspect
  
  asterisk_extension = skype_user_translation({ :translate => 'to_asterisk', :value => callerid })
  if asterisk_extension
    dial "SIP/" + asterisk_extension
  end  
  
}
