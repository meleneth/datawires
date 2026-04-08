FactoryBot.define do
  factory :edit_affordance do
    for_schema_document { nil }
    affordance_document { nil }
    name { "MyString" }
  end
end
