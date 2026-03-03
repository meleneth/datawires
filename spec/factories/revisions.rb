FactoryBot.define do
  factory :revision do
    document { nil }
    parent_revision { nil }
    body { "" }
    message { "MyText" }
    created_by { nil }
  end
end
