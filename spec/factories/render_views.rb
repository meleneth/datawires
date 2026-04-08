FactoryBot.define do
  factory :render_view do
    for_schema_document { nil }
    view_document { nil }
    name { "MyString" }
  end
end
