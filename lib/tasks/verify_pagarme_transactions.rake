desc "Verify all transactions in pagarme for a given date range and check their consistency in our database"
task :verify_pagarme_transactions, [:start_date, :end_date]  => :environment do |task, args|
  args.with_defaults(start_date: Date.today - 1, end_date: Date.today)
  Rails.logger.info "Verifying transactions in range: #{args.inspect}"

  def find_transactions_by_dates(start_date, end_date, from = 0, size = 50)
    request = PagarMe::Request.new('/search', 'GET')
    query = {
      type: 'transaction',
      query: {
        from: from,
        size: size,
        query: {
          range: {
            date_created: {
              gte: start_date,
              lte: end_date
            }
          }
        }
      }.to_json
    }
    Rails.logger.info query.inspect
    request.parameters.merge!(query)
    request.run
  end

  PagarMe.api_key = CatarsePagarme.configuration.api_key
  first_collection = find_transactions_by_dates(args[:start_date], args[:end_date])
  total_pages = first_collection['hits']['total'] / 50

  total_pages.times do |page|
    result = find_transactions_by_dates(args[:start_date], args[:end_date], page)
    puts result['hits']['hits'].size
  end
end
