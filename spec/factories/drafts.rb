FactoryBot.define do
  factory :draft do
    document { nil }
    based_on_revision { nil }
    body { "" }
    created_by { nil }
  end
end
