module PostsHelper
  def pf_selected_class(list, param_value)
    case list
    when Array
      return "is-btn-green-selected" if list.include?(param_value)
    when String
      return "is-btn-green-selected" if list == param_value
    end

    return ""
  end
end
