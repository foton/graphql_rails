# frozen_string_literal: true

require_relative 'query_action'
require_relative 'mutation_action'

module Graphiti
  class Router
    # Generates graphql actions based on resource name and options
    class ResourceActionsBuilder
      AVAILABLE_ACTIONS = %i[show index create update destroy].freeze

      def initialize(name, only: nil, except: [])
        @name = name.to_s

        @autogenerated_action_names = initial_action_names(only, except, AVAILABLE_ACTIONS)
      end

      def actions
        @actions ||= initial_actions
      end

      def query(*args)
        actions << build_query(*args)
      end

      def mutation(*args)
        actions << build_mutation(*args)
      end

      private

      attr_reader :autogenerated_action_names, :name

      def initial_actions
        actions = initial_query_actions
        actions << build_mutation(:create, on: :member) if autogenerated_action_names.include?(:create)
        actions << build_mutation(:update, on: :member) if autogenerated_action_names.include?(:update)
        actions << build_mutation(:destroy, on: :member) if autogenerated_action_names.include?(:destroy)
        actions
      end

      def initial_query_actions
        actions = Set.new

        if autogenerated_action_names.include?(:show)
          actions << QueryAction.new(resource_name(:member), to: "#{name}#show")
        end

        if autogenerated_action_names.include?(:index)
          actions << QueryAction.new(resource_name(:collection), to: "#{name}#index")
        end

        actions
      end

      def build_mutation(*args)
        build_action(MutationAction, *args)
      end

      def build_query(*args)
        build_action(QueryAction, *args)
      end

      def build_action(builder, action, on: :member) # rubocop:disable Naming/UncommunicativeMethodParamName
        action_name = "#{action}_#{resource_name(on)}"
        builder.new(action_name, to: "#{name}##{action}")
      end

      def initial_action_names(only, except, available)
        alowed_actions = Array(only || available) & available
        only_actions = alowed_actions.map(&:to_sym) - Array(except).map(&:to_sym)
        Set.new(only_actions)
      end

      def resource_name(type)
        type.to_sym == :member ? name.singularize : name
      end
    end
  end
end