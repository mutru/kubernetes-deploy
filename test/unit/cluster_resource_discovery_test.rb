# frozen_string_literal: true
require 'test_helper'

class ClusterResourceDiscoveryTest < Krane::TestCase
  def test_global_resource_kinds_failure
    crd = mocked_cluster_resource_discovery(nil, success: false)
    kinds = crd.global_resource_kinds
    assert_equal(kinds, [])
  end

  def test_global_resource_kinds_success
    crd = mocked_cluster_resource_discovery(api_resources_full_response)
    kinds = crd.global_resource_kinds
    assert_equal(kinds.length, api_resources_full_response.split("\n").length - 1)
    %w(MutatingWebhookConfiguration ComponentStatus CustomResourceDefinition).each do |kind|
      assert_includes(kinds, kind)
    end
  end

  def test_prunable_resources
    Krane::Kubectl.any_instance.stubs(:run).with("api-versions", attempts: 5, use_namespace: false)
      .returns([api_versions_full_response, "", stub(success?: true)])
    crd = mocked_cluster_resource_discovery(api_resources_full_response)
    kinds = crd.prunable_resources(namespaced: false)

    assert_equal(kinds.length, 13)
    %w(scheduling.k8s.io/v1beta1/PriorityClass storage.k8s.io/v1beta1/StorageClass).each do |kind|
      assert_includes(kinds, kind)
    end
    %w(node namespace).each do |black_lised_kind|
      assert_empty kinds.select { |k| k.downcase.include?(black_lised_kind) }
    end
  end

  private

  def mocked_cluster_resource_discovery(response, success: true)
    Krane::Kubectl.any_instance.stubs(:run)
      .with("api-resources", "--namespaced=false", attempts: 5, use_namespace: false, output: "wide")
      .returns([response, "", stub(success?: success)])
    Krane::ClusterResourceDiscovery.new(task_config: task_config, namespace_tags: [])
  end

  def api_versions_full_response
    File.read(File.join(fixture_path('for_unit_tests'), "api_versions.txt"))
  end

  def api_resources_full_response
    File.read(File.join(fixture_path('for_unit_tests'), "api_resources.txt"))
  end
end
