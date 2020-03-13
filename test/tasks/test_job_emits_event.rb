# frozen_string_literal: true

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

            it 'looks for the expected job task' do
                monitoring_task = add_monitoring_task
                expect_execution { monitoring_task.start! }
                    .to { emit monitoring_task.start_event }
                assert_equal task, monitoring_task.job_task
            end

            it 'fails to start if the expected job task cannot be found' do
                monitoring_task = add_monitoring_task(monitored_job_id: 30)
                expect_execution { monitoring_task.start! }
                    .to { fail_to_start monitoring_task }
            end

            it 'fails to start if the expected job task does not have the '\
               'expected event' do
                monitoring_task = add_monitoring_task(event_name: :does_not_exist)
                expect_execution { monitoring_task.start! }
                    .to do
                        have_error_matching(
                            Roby::CommandFailed
                            .match.with_origin(monitoring_task)
                        )
                    end
            end

            it 'emits success if the task\'s expected event is already emitted' do
                monitoring_task = add_monitoring_task
                execute do
                    task.start!
                    task.success_event.emit
                end
                expect_execution { monitoring_task.start! }
                    .to { emit monitoring_task.success_event }
            end

            it 'gets an error if the task\'s expected event is already unreachable' do
                monitoring_task = add_monitoring_task
                execute { task.success_event.unreachable! }
                expect_execution { monitoring_task.start! }
                    .to do
                        have_error_matching(
                            Roby::ChildFailedError
                            .match.with_origin(task.success_event)
                        )
                    end
            end
            it 'emits success if the task\'s expected event is emitted' do
                monitoring_task = add_monitoring_task
                expect_execution do
                    task.start!
                    monitoring_task.start!
                    task.success_event.emit
                end.to { emit monitoring_task.success_event }
            end

            it 'gets an error if the task\'s expected event becomes unreachable' do
                monitoring_task = add_monitoring_task
                expect_execution do
                    monitoring_task.start!
                    task.success_event.unreachable!
                end.to do
                    have_error_matching(
                        Roby::ChildFailedError
                        .match.with_origin(task.success_event)
                    )
                end
            end

            def add_monitoring_task(
                monitored_job_id: 20, event_name: :success, timeout: 2
            )
                monitoring_task = JobEmitsEvent.new(
                    monitored_job_id: monitored_job_id,
                    event_name: event_name,
                    timeout: timeout
                )
                plan.add(monitoring_task)
                monitoring_task
            end
        end
    end
end
