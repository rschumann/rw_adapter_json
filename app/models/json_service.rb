require 'oj'

class JsonService
  def initialize(id, options = {})
    @id = id
    @options_hash = options
    initialize_options
  end

  def connect_data
    if @options_hash.present?
      options_query
    else
      index_query
    end
  end

  private

    def initialize_options
      @options = QueryParams.sanitize(@options_hash)
      @options.keys.each { |k| instance_variable_set("@#{k}", @options[k]) }
    end

    def index_query
      Dataset.find(@id).data
    end

    def options_query
      # SELECT
      filter = Filters::Select.apply_select(@id, @select, @aggr_func, @aggr_by)
      # WHERE
      filter += ' WHERE ' if @not_filter.present? || @filter.present?
      filter += Filters::FilterWhere.apply_where(@filter, nil) if @filter.present?
      # WHERE NOT
      filter += ' AND' if @not_filter.present? && @filter.present?
      filter += Filters::FilterWhere.apply_where(nil, @not_filter) if @not_filter.present?
      # # GROUP BY
      filter += Filters::GroupBy.apply_group_by(@group) if @group.present?
      # ORDER
      filter += Filters::Order.apply_order(@order) if @order.present?
      # LIMIT
      filter += Filters::Limit.apply_limit(@limit) if @limit.present? && !@limit.include?('all')
      begin
        Dataset.execute_data_query(filter).to_ary
      rescue => e
        error = Oj.dump({ error: [e.cause.to_s.split(' ').join(' ')] })
        Oj.load(error)
      end
    end
end
