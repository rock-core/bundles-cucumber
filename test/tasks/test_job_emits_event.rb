require 'cucumber/models/tasks/job_emits_event'
require 'roby/tasks/simple'

module Cucumber
    module Tasks
        describe JobEmitsEvent do
            attr_reader :task, :job_task, :monitoring_task

            before do
                plan.add(@task = Roby::Tasks::Simple.new)
                job_task_m = Roby::Tasks::Simple.new_submodel do
                    provides Roby::Interface::Job
                end
                task.planned_by(@job_task = job_task_m.new(job_id: 20))
            end

            it "looks for the expected job task" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 20, event_name: :success, timeout: 2))
                assert_event_emission(monitoring_task.start_event) do
                    monitoring_task.start!
                end
                assert_equal task, monitoring_task.job_task
            end
            it "fails to start if the expected job task cannot be found" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 30, event_name: :success, timeout: 2))
                assert_task_fails_to_start(monitoring_task, Roby::CodeError, original_exception: ArgumentError) do
                    monitoring_task.start!
                end
            end
            it "fails to start if the expected job task does not have the expected event" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 30, event_name: :does_not_exist, timeout: 2))
                assert_task_fails_to_start(monitoring_task, Roby::CodeError, original_exception: ArgumentError) do
                    monitoring_task.start!
                end
            end
            it "emits success if the task's expected event is already emitted" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 20, event_name: :success, timeout: 2))
                task.start!
                task.success_event.emit
                assert_event_emission(monitoring_task.success_event) do
                    monitoring_task.start!
                end
            end
            it "gets an error if the task's expected event is already unreachable" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 20, event_name: :success, timeout: 2))
                task.success_event.unreachable!
                assert_fatal_exception(Roby::ChildFailedError, failure_point: task.success_event, tasks: [task, monitoring_task]) do
                    monitoring_task.start!
                end
            end
            it "emits success if the task's expected event is emitted" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 20, event_name: :success, timeout: 2))
                task.start!
                monitoring_task.start!
                assert monitoring_task.running?
                assert_event_emission(monitoring_task.success_event) do
                    task.success_event.emit
                end
            end
            it "gets an error if the task's expected event becomes unreachable" do
                plan.add(monitoring_task = JobEmitsEvent.new(monitored_job_id: 20, event_name: :success, timeout: 2))
                monitoring_task.start!
                assert_fatal_exception(Roby::ChildFailedError, failure_point: task.success_event, tasks: [task, monitoring_task]) do
                    task.success_event.unreachable!
                end
            end
        end
    end
end
