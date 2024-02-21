class Fetcher
  def fetch
    response = HTTParty.post(
      'https://nxt.chessbomb.com/events/api/searchv2',
      body: {
        searchFor: '',
        sortBy: 'relevance',
        timeFilter: 'current',
        size: 8,
        featured: true,
        home: false
      }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    JSON.parse(response.body).map{|event| event['event']}
  end
end
