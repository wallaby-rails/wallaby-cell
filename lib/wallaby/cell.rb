# frozen_string_literal: true

module Wallaby
  # A Cell template/partial is a Ruby view object.
  class Cell
    VARIABLES = %i(
      @__context
      @__local_assigns
      @__buffer
    ).freeze

    KEYS = %w(
      __context
      __local_assigns
      __buffer
    ).freeze

    # @!attribute [r] context
    # @return [Object] view context
    def context
      @__context
    end

    # @!attribute [r] local_assigns
    # @return [Hash] a list of local_assigns
    def local_assigns
      @__local_assigns
    end

    # @!attribute [r] buffer
    # @return [String] output string buffer
    def buffer
      @__buffer
    end

    delegate(*ERB::Util.singleton_methods, to: ERB::Util)
    delegate :yield, :formats, :concat, :content_tag, to: :context

    # @param context [ActionView::Base] view context
    # @param local_assigns [Hash] local variables
    # @param buffer [ActionView::OutputBuffer.new, nil] output buffer
    def initialize(context, local_assigns, buffer = nil)
      update context, local_assigns, buffer
    end

    # @param context [ActionView::Base] view context
    # @param local_assigns [Hash] local variables
    # @param buffer [ActionView::OutputBuffer.new, nil] output buffer
    def update(context, local_assigns, buffer = nil)
      @__context = context
      @__local_assigns = local_assigns
      @__buffer = buffer ||= ActionView::OutputBuffer.new
      context.output_buffer ||= buffer
    end

    # @note this is a template method that can be overridden by subclasses
    # Produce output for both the template and partial.
    # @return [ActionView::OutputBuffer, String]
    def to_render; end

    # @note this is a template method that can be overridden by subclasses
    # Produce output for the template.
    # @return [ActionView::OutputBuffer, String]
    def to_template(&block)
      to_render(&block)
    end

    # @note this is a template method that can be overridden by subclasses
    # Produce output for the partial.
    # @return [ActionView::OutputBuffer, String]
    def to_partial(&block)
      to_render(&block)
    end

    # Override the original render method to ensure to copy
    # instance variables back to view {#context}
    # @return [ActionView::OutputBuffer, String]
    # @see ActionView::Base#render
    def render(*args)
      copy_instance_variables_to(context)
      context.render(*args)
    end

    # Produce output for the {Wallaby::Cell} template.
    # @return [ActionView::OutputBuffer, String]
    def render_template(&block)
      copy_instance_variables_from(context)
      content = to_template(&block)
      copy_instance_variables_to(context)
      buffer == content ? buffer : buffer << content
    end

    # Produce output for the {Wallaby::Cell} partial.
    # @return [ActionView::OutputBuffer, String]
    def render_partial(&block)
      copy_instance_variables_from(context)
      content = to_partial(&block)
      copy_instance_variables_to(context)
      buffer == content ? buffer : buffer << content
    end

    private

    # NOTE: instance variables for a view is stored in {ActionView::Base#assigns]
    def copy_instance_variables_from(context)
      context.assigns.each do |key, value|
        next if KEYS.include? key

        instance_variable_set :"@#{key}", value
      end
    end

    # NOTE: instance variables for a view is stored in {ActionView::Base#assigns]
    def copy_instance_variables_to(context)
      instance_variables.each do |symbol|
        next if VARIABLES.include? symbol

        context.assigns[symbol.to_s[1..-1]] = remove_instance_variable symbol
      end
    end

    # Delegate missing method to {#context}
    def method_missing(method_id, *args, &block)
      return local_assigns[method_id] if local_assigns_reader?(method_id)
      return super unless context.respond_to? method_id

      context.public_send method_id, *args, &block
    end

    # Delegate missing method check to {#context}
    def respond_to_missing?(method_id, _include_private)
      local_assigns_reader?(method_id) \
        || context.respond_to?(method_id) \
        || super
    end

    # Check if the method_id is a key of {#local_assigns}
    def local_assigns_reader?(method_id)
      local_assigns.key?(method_id)
    end
  end
end
