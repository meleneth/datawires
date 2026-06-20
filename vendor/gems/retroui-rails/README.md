# retroui-rails

## What is this?

`retroui-rails` is a Rails/ViewComponent port of RetroUI's Tailwind-first component model.

It is not a plain CSS component gem. Components render Tailwind utility classes directly, and Tailwind is required in the host application. The intent is similar to shadcn-style ownership: install the gem, render components, then vendor the component source when you want to own and modify it.

RetroUI is created by Arif Hossain and the RetroUI contributors at https://retroui.dev and https://github.com/Logging-Studio/RetroUI. This Rails gem is an independent adaptation. Mistakes, omissions, awkward Rails API choices, or broken adaptations here belong to this port and its instructions, not to the original RetroUI authors.

## Installation

This gem is intended to be installed from its Git repository, not from RubyGems.

Add the gem to your Rails app:

```ruby
gem "retroui-rails", git: "https://github.com/meleneth/retroui-rails.git"
```

Then run:

```sh
bundle install
rails generate retro_ui:install
```

Use a branch, tag, or commit ref in your Gemfile when you want to pin an app to a specific version of this repository:

```ruby
gem "retroui-rails",
  git: "https://github.com/meleneth/retroui-rails.git",
  branch: "main"
```

`retroui-rails` depends on Rails, ViewComponent, and Stimulus for interactive Hotwire components. It does not require React, Node, or vendored fonts.

## Tailwind setup

The host app must compile Tailwind classes used by gem components. There is no Tailwind-free fallback.

Include the RetroUI theme tokens in a stylesheet compiled by your app:

```css
@import "retro_ui/rails/theme.css";
```

Configure Tailwind to scan the classes used by:

- app-owned components, such as `app/components/**/*.{rb,erb}`
- gem-provided components, such as the installed gem's `app/components/retro_ui/rails/**/*.{rb,erb}`
- vendored components, such as `app/components/retro_ui/**/*.{rb,erb}`

If your Tailwind setup cannot scan gem files reliably, vendor the components:

```sh
rails generate retro_ui:vendor
```

## Using components

```erb
<%= render RetroUI::Rails::ButtonComponent.new(label: "Start") %>

<%= render RetroUI::Rails::ButtonComponent.new(href: "/docs", variant: :secondary) do %>
  Read Docs
<% end %>

<%= render RetroUI::Rails::BadgeComponent.new(variant: :secondary) do %>
  New
<% end %>

<%= render RetroUI::Rails::AlertComponent.new do %>
  <%= render RetroUI::Rails::AlertTitleComponent.new do %>
    Autosave complete
  <% end %>
  <%= render RetroUI::Rails::AlertDescriptionComponent.new do %>
    Your changes are safely tucked away.
  <% end %>
<% end %>

<%= render RetroUI::Rails::LabelComponent.new(text: "Email", for_id: "email") %>
<%= render RetroUI::Rails::InputComponent.new(type: :email, name: "email", html_options: { id: "email" }) %>
<%= render RetroUI::Rails::TextareaComponent.new(name: "message") %>
<%= render RetroUI::Rails::CheckboxComponent.new(name: "confirm") %>
<%= render RetroUI::Rails::RadioComponent.new(name: "plan", value: "pro") %>
<%= render RetroUI::Rails::SelectComponent.new(name: "size", options: [["Small", "s"], ["Large", "l"]]) %>

<%= render RetroUI::Rails::SeparatorComponent.new %>
<%= render RetroUI::Rails::SkeletonComponent.new(html_options: { class: "h-8 w-full" }) %>
<%= render RetroUI::Rails::ProgressComponent.new(value: 40) %>
<%= render RetroUI::Rails::SwitchComponent.new(name: "enabled") %>

<%= render RetroUI::Rails::BarChartComponent.new(
  title: "Shipments",
  data: [{ month: "Jan", count: 12 }, { month: "Feb", count: 18 }],
  x_key: :month,
  y_key: :count
) %>

<%= render RetroUI::Rails::PieChartComponent.new(
  title: "Plan Mix",
  data: [{ plan: "Free", users: 32 }, { plan: "Pro", users: 18 }],
  label_key: :plan,
  value_key: :users
) %>

<%= render RetroUI::Rails::AvatarComponent.new do %>
  <%= render RetroUI::Rails::AvatarFallbackComponent.new(text: "RU") %>
<% end %>

<%= render RetroUI::Rails::AspectRatioComponent.new(ratio: "16/9") do %>
  <img src="/preview.png" alt="Preview" class="h-full w-full object-cover">
<% end %>

<%= render RetroUI::Rails::BreadcrumbComponent.new do %>
  <%= render RetroUI::Rails::BreadcrumbListComponent.new do %>
    <%= render RetroUI::Rails::BreadcrumbItemComponent.new do %>
      <%= render RetroUI::Rails::BreadcrumbLinkComponent.new(href: "/", text: "Home") %>
    <% end %>
    <%= render RetroUI::Rails::BreadcrumbSeparatorComponent.new %>
    <%= render RetroUI::Rails::BreadcrumbItemComponent.new do %>
      <%= render RetroUI::Rails::BreadcrumbPageComponent.new(text: "Docs") %>
    <% end %>
  <% end %>
<% end %>

<%= render RetroUI::Rails::PaginationComponent.new do %>
  <%= render RetroUI::Rails::PaginationContentComponent.new do %>
    <%= render RetroUI::Rails::PaginationItemComponent.new do %>
      <%= render RetroUI::Rails::PaginationLinkComponent.new(href: "?page=1", label: "1", active: true) %>
    <% end %>
  <% end %>
<% end %>

<%= render RetroUI::Rails::TypographyComponent.new(as: :h2, text: "Inventory") %>
<%= render RetroUI::Rails::CodeComponent.new(text: "rails generate retro_ui:vendor") %>
<%= render RetroUI::Rails::KbdComponent.new(text: "K") %>

<%= render RetroUI::Rails::ToastViewportComponent.new do %>
  <%= render RetroUI::Rails::ToastComponent.new(duration: 4000) do %>
    <%= render RetroUI::Rails::ToastTitleComponent.new(text: "Saved") %>
    <%= render RetroUI::Rails::ToastDescriptionComponent.new(text: "Your changes were saved.") %>
    <%= render RetroUI::Rails::ToastCloseComponent.new %>
  <% end %>
<% end %>

<%= render RetroUI::Rails::CardComponent.new do %>
  <%= render RetroUI::Rails::CardHeaderComponent.new do %>
    <%= render RetroUI::Rails::CardTitleComponent.new do %>
      Save Point
    <% end %>
    <%= render RetroUI::Rails::CardDescriptionComponent.new do %>
      Your progress is mostly imaginary.
    <% end %>
  <% end %>

  <%= render RetroUI::Rails::CardContentComponent.new do %>
    Continue?
  <% end %>
<% end %>

<%= render RetroUI::Rails::TableComponent.new do %>
  <%= render RetroUI::Rails::TableHeaderComponent.new do %>
    <%= render RetroUI::Rails::TableRowComponent.new do %>
      <%= render RetroUI::Rails::TableHeadComponent.new do %>Quest<% end %>
      <%= render RetroUI::Rails::TableHeadComponent.new do %>Status<% end %>
    <% end %>
  <% end %>
  <%= render RetroUI::Rails::TableBodyComponent.new do %>
    <%= render RetroUI::Rails::TableRowComponent.new do %>
      <%= render RetroUI::Rails::TableCellComponent.new do %>Ship gem<% end %>
      <%= render RetroUI::Rails::TableCellComponent.new do %>In progress<% end %>
    <% end %>
  <% end %>
<% end %>
```

Hotwire-backed components use Stimulus controllers. Register the controllers you use with your Stimulus application:

```ruby
# config/importmap.rb
pin "retro_ui/rails/controllers/accordion_controller", to: "retro_ui/rails/controllers/accordion_controller.js"
pin "retro_ui/rails/controllers/tabs_controller", to: "retro_ui/rails/controllers/tabs_controller.js"
pin "retro_ui/rails/controllers/dialog_controller", to: "retro_ui/rails/controllers/dialog_controller.js"
pin "retro_ui/rails/controllers/dropdown_menu_controller", to: "retro_ui/rails/controllers/dropdown_menu_controller.js"
pin "retro_ui/rails/controllers/popover_controller", to: "retro_ui/rails/controllers/popover_controller.js"
pin "retro_ui/rails/controllers/tooltip_controller", to: "retro_ui/rails/controllers/tooltip_controller.js"
pin "retro_ui/rails/controllers/toast_controller", to: "retro_ui/rails/controllers/toast_controller.js"
pin "retro_ui/rails/controllers/chart_controller", to: "retro_ui/rails/controllers/chart_controller.js"
pin "d3", to: "https://cdn.jsdelivr.net/npm/d3@7/+esm"
```

```js
import AccordionController from "retro_ui/rails/controllers/accordion_controller"
import ChartController from "retro_ui/rails/controllers/chart_controller"
import TabsController from "retro_ui/rails/controllers/tabs_controller"
import DialogController from "retro_ui/rails/controllers/dialog_controller"
import DropdownMenuController from "retro_ui/rails/controllers/dropdown_menu_controller"
import PopoverController from "retro_ui/rails/controllers/popover_controller"
import TooltipController from "retro_ui/rails/controllers/tooltip_controller"
import ToastController from "retro_ui/rails/controllers/toast_controller"

application.register("retro-ui--accordion", AccordionController)
application.register("retro-ui--chart", ChartController)
application.register("retro-ui--tabs", TabsController)
application.register("retro-ui--dialog", DialogController)
application.register("retro-ui--dropdown-menu", DropdownMenuController)
application.register("retro-ui--popover", PopoverController)
application.register("retro-ui--tooltip", TooltipController)
application.register("retro-ui--toast", ToastController)
```

Chart components are a Rails-native divergence from upstream RetroUI. Upstream uses React/Recharts; this gem renders ViewComponents plus a D3-backed Stimulus controller. The public chart names follow the upstream registry (`AreaChartComponent`, `BarChartComponent`, `LineChartComponent`, `PieChartComponent`), but the implementation and API are intentionally data-oriented for Rails.

## Theme tokens

The theme stylesheet defines CSS variables only. Component styling remains in Tailwind utility classes.

Tokens include background, foreground, card, primary, secondary, muted, accent, destructive, border, and hard offset shadow variables. Configure Tailwind colors and shadows to read from these variables so utilities such as `bg-primary`, `text-primary-foreground`, `bg-card`, `border-border`, and `shadow-md` resolve to the RetroUI theme.

## Dark mode

Dark mode is an application concern. `retroui-rails` keeps the theme layer token-based, so the simplest approach is to override the same CSS variables under a selector your app controls:

```css
[data-theme="dark"] {
  color-scheme: dark;
  --background: 230 24% 8%;
  --foreground: 52 100% 92%;
  --card: 230 22% 12%;
  --card-foreground: 52 100% 92%;
  --primary: 52 100% 54%;
  --primary-foreground: 230 24% 8%;
  --secondary: 190 95% 52%;
  --secondary-foreground: 230 24% 8%;
  --muted: 230 16% 22%;
  --muted-foreground: 52 24% 76%;
  --accent: 330 100% 68%;
  --accent-foreground: 230 24% 8%;
  --destructive: 0 84% 62%;
  --destructive-foreground: 0 0% 100%;
  --border: 52 100% 88%;
}
```

Then toggle the attribute on the document element:

```js
document.documentElement.dataset.theme =
  document.documentElement.dataset.theme === "dark" ? "light" : "dark"
```

Because components use Tailwind utilities backed by CSS variables, classes such as `bg-card`, `text-foreground`, `border-border`, and `shadow-md` update when the token values change. The dummy demo app includes a small Stimulus controller showing this pattern with `localStorage` persistence.

## Vendoring for customization

Vendoring copies the current gem component source into your application:

```sh
rails generate retro_ui:vendor
```

Files are copied to `app/components/retro_ui`, `app/javascript/controllers/retro_ui`, and `app/assets/stylesheets/retro_ui/theme.css`. Namespaces are rewritten from `RetroUI::Rails` to `RetroUI`, so vendored components are application code and do not depend on the engine namespace.

Vendored components currently include button, card, badge, alert, input, textarea, label, checkbox, radio, select, separator, skeleton, progress, table, avatar, aspect ratio, breadcrumb, pagination, typography, code, kbd, switch, accordion, tabs, dialog, dropdown menu, popover, tooltip, toast, and D3 chart primitives.

Existing files are not overwritten unless you pass `--force`:

```sh
rails generate retro_ui:vendor --force
```

Future gem updates will not automatically alter vendored copies.

## Development

Install dependencies and run the test suite:

```sh
bundle install
bundle exec rspec
```

The test dummy app lives in `spec/dummy`.

Run the dummy demo app:

```sh
cd spec/dummy
bundle exec ruby bin/rails server -b 127.0.0.1 -p 3000
```

Then open `http://127.0.0.1:3000/`.

## License

`retroui-rails` is released under the MIT License. See [LICENSE](LICENSE).

RetroUI is also MIT licensed by Arif Hossain. See [NOTICE.md](NOTICE.md) for attribution.
