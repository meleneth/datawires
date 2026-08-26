# frozen_string_literal: true

module BoardsHelper
  def format_board_statistic(value)
    return "—" if value.nil?
    return value unless value.is_a?(Numeric)

    number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
  end
end
