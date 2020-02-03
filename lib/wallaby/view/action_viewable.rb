# frozen_string_literal: true

module Wallaby
  module View
    # This module overrides Rails core methods {#lookup_context} and {#_prefixes}
    # to provide better performance and more lookup prefixes.
    module ActionViewable
      extend ActiveSupport::Concern

      class << self
        # @!attribute prefix_options
        # It stores the options for {#_prefixes}. It can inherit options from superclass.
        # @return [Hash] prefix options
      end

      class_methods do
        attr_writer :prefix_options

        def prefix_options
          @prefix_options ||= View.try_to superclass, :prefix_options
        end
      end

      # @!method original_lookup_context
      # Original method of {#lookup_context}
      # @return [ActionView::LookupContext]

      # @!method original_prefixes
      # Original method of {#_prefixes}
      # @return [Array<String>]

      # @!method lookup_context
      # Override
      # {https://github.com/rails/rails/blob/master/actionview/lib/action_view/view_paths.rb#L97 lookup_context}
      # to provide caching for template/partial lookup.
      # @return {Wallaby::View::CustomLookupContext}

      # (see #lookup_context)
      def override_lookup_context
        @_lookup_context ||= # rubocop:disable Naming/MemoizedInstanceVariableName
          CustomLookupContext.convert(original_lookup_context, prefixes: _prefixes)
      end

      # @!method _prefixes(prefixes: nil, controller_path: nil, action_name: nil, themes: nil, options: nil, &block)
      # Override {https://github.com/rails/rails/blob/master/actionview/lib/action_view/view_paths.rb#L90 _prefixes}
      # to allow other (e.g. {Wallaby::View::CustomPrefixes#action_name},
      # {Wallaby::View::CustomPrefixes#themes}) to be added to the prefixes list.
      # @param prefixes [Array<String>] the base prefixes
      # @param action_name [String] the action name to add to the prefixes list
      # @param themes [String] the theme name to add to the prefixes list
      # @param options [Hash] the options for {Wallaby::View::CustomPrefixes}
      # @return [Array<String>]

      # (see #_prefixes)
      def override_prefixes(
        prefixes: nil,
        action_name: nil,
        themes: nil,
        options: nil, &block
      )
        @_prefixes ||= # rubocop:disable Naming/MemoizedInstanceVariableName
          CustomPrefixes.execute(
            prefixes: prefixes || original_prefixes,
            action_name: action_name || params[:action],
            themes: themes || self.class.themes,
            options: options || self.class.prefix_options, &block
          )
      end
    end
  end
end
