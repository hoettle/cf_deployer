class StackHelper
    def self.init(cloudformation, environment_name)
      @@all_stacks = get_all_stacks(cloudformation)
      @@tagged_environment_name = environment_name
    end
  
    def self.get_stack_output(tag_type, output_name)
      stack_outputs = get_stack_outputs(tag_type)
      get_stack_output_by_name(stack_outputs, tag_type, output_name).first.output_value
    end
  
    def self.output_value_exists?(tag_type, output_name)
      get_stack_output(tag_type, output_name)
      return true
    rescue
      return false
    end

    def self.get_stack_output_by_multiple_tags_and_name(tags, output_name)
      stacks_outputs = get_stack_outputs_by_multiple_tags(tags)
      get_stack_output_by_name(stacks_outputs, tags, output_name).first.output_value
    end

    def self.get_stack_outputs_by_multiple_tags(tags)
      stacks_containing_all_tags = @@all_stacks.select { |s| include_all_tags(s, tags) }.collect{ |stack| stack.outputs }.flatten
      raise "Could not find stack with tags [#{tags.each do |tag| pretty_tag_type(tag) end}]" if stacks_containing_all_tags.empty?
      stacks_containing_all_tags
    end

    def self.get_stack_parameter(tag_type, parameter_name)
      stack_parameters = get_stack_parameters(tag_type)
      get_stack_parameter_by_name(stack_parameters, tag_type, parameter_name).first.parameter_value
    end
  
    def self.parameter_value_exists?(tag_type, parameter_name)
      get_stack_parameter(tag_type, parameter_name)
      return true
    rescue
      return false
    end
  
    private
  
    def self.get_stack_outputs(tag_type)
      stacks_of_wanted_type = @@all_stacks.select { |s| s[:tags].include?(tag_type) && s[:tags].include?(environment_tag) }.collect{ |stack| stack.outputs }.flatten
      raise "Could not find stack with tags [#{pretty_tag_type(tag_type)}] in environment [#{environment_tag[:value]}]" if stacks_of_wanted_type.empty?
      stacks_of_wanted_type
    end
  
    def self.get_stack_output_by_name(stack_outputs, tags, output_name)
      stacks_with_output_value = stack_outputs.select { |stack| stack.output_key.include?(output_name) }
      raise "Stack with tags [#{tags}] did not contain output value [#{output_name}]" if stacks_with_output_value.empty?
      raise "Stack with tags [#{tags}] contains more than 1 outputs of [#{output_name}]" if stacks_with_output_value.size > 1
      stacks_with_output_value
    end
  
    def self.get_stack_parameters(tag_type)
      stacks_of_wanted_type = @@all_stacks.select { |s| s[:tags].include?(tag_type) && s[:tags].include?(environment_tag) }.collect{ |stack| stack.parameters }.flatten
      raise "Could not find stack with tags [#{pretty_tag_type(tag_type)}] in environment [#{environment_tag[:value]}]" if stacks_of_wanted_type.empty?
      stacks_of_wanted_type
    end
  
    def self.get_stack_parameter_by_name(stack_parameters, tag_type, parameter_name)
      stacks_with_parameter_value = stack_parameters.select { |stack| stack.parameter_key.include?(parameter_name) }
      raise "Stack with tags [#{pretty_tag_type(tag_type)}] did not contain parameter [#{parameter_name}]" if stacks_with_parameter_value.empty?
      raise "Stack with tags [#{pretty_tag_type(tag_type)}] contains more than 1 parameters of [#{parameter_name}]" if stacks_with_parameter_value.size > 1
      stacks_with_parameter_value
    end
  
    def self.pretty_tag_type(tag)
      "#{tag[:key]}:#{tag[:value]}"
    end
  
    def self.pretty_env_type(tag)
      "#{tag[:environment]}:#{tag[:value]}"
    end
  
    def self.environment_tag
      {key: "Environment", value: @@tagged_environment_name}
    end
  
    def self.get_all_stacks(cloudformation)
      stacks_page = cloudformation.describe_stacks
      all_stacks = stacks_page.stacks
      until stacks_page[:next_token].nil? || stacks_page[:next_token].empty? do
        stacks_page = cloudformation.describe_stacks({next_token: stacks_page.next_token,})
        all_stacks += stacks_page.stacks
      end
      all_stacks
    end

    def self.include_all_tags(s, tags)
      stack_includes_all_tags = true
      tags.each do |tag|
        stack_includes_all_tags &= s[:tags].include?(tag)
      end
      stack_includes_all_tags
  end
end