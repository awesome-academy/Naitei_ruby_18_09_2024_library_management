Ransack.configure do |config|
  config.add_predicate "after",
    arel_predicate: "gteq",
    formatter: proc {|v| v.to_date},
    validator: proc {|v| v.present?},
    type: :date
end
