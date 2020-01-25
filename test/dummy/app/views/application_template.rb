class ApplicationTemplate < Wallaby::Cell
  def file
    __FILE__
  end

  def to_render
    file[%r{(?<=app/views/).+}]
  end

  def to_template
    content_tag :h1, to_render
  end
end
