class StreamUrlBuilder
  class << self
    def build(platform, channel_code)
      case platform
      when 'twitch'
        "https://www.twitch.tv/#{channel_code}"
      when 'youtube'
        "https://www.youtube.com/channel/#{channel_code}"
      when 'kick'
        "https://kick.com/#{channel_code}"
      else
        platform
      end
    end
  end
end
