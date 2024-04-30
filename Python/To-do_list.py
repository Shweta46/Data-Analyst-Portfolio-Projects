list_of_tasks = []
def addTask():
    add_task = input('Enter a task:')
    list_of_tasks.append(add_task)
    print(f'{add_task} task is added.')

def completedTasks():
    flag = allTask()
    while flag:
        try:
            delete_task = int(input('Enter the completed task number: '))
            if (delete_task >= 0) and (delete_task < len(list_of_tasks)):
                list_of_tasks.pop(delete_task)
                if len(list_of_tasks) == 0:
                    print('All tasks are COMPLETED!!! GOOD JOB!!!')
                    flag = False
                print(f'The task {delete_task} is completed.')
                allTask()
            else:
                print(f'The task number {delete_task} doesnt exist.')
        except:
            print(f'Invalid input.')
        more = input("Do you want to delete more tasks? (y/n):")
        if more.lower() == 'n' or more.lower() != 'y':
            break
        elif more.lower() == 'y':
            if len(list_of_tasks) == 0:
                print('All tasks are COMPLETED!!! GOOD JOB!!!')
                break

def allTask():
    if not list_of_tasks:
        print('All tasks are COMPLETED!!! GOOD JOB!!!')
        return False
    else:
        print("All tasks:")
        for i, j in enumerate(list_of_tasks):
            print(f'{i}. {j}')
        return True

def editTask():
    allTask()
    while True:
        try:
            task_num_input = input("Enter the task you want to edit (press Enter to cancel): ")
            if task_num_input == "":
                break
            task_num = int(task_num_input)
            if task_num < 0 or task_num > len(list_of_tasks):
                print("Invalid task number. Please enter a valid task number.")
                continue
            edited_task = input('Enter the edited task:')
            list_of_tasks[task_num - 1] = edited_task
        except ValueError:
            print('Invalid input. Enter a valid number.')

if __name__ == "__main__":
    print("The To DO list, JUST DO IT:")
    while True:
        print('\n')
        print('Select input based on respective options:')
        print("1 = Add tasks")
        print('2 = Completed tasks')
        print('3 = List all the tasks')
        print('4 = Edit a task')
        print('5 = Exit the To DO list.')

        selection = input("Enter your choice:")
        if selection == '1':
            addTask()
        elif selection == '2':
            completedTasks()
        elif selection == '3':
            allTask()
        elif selection == '4':
            editTask()
        elif selection == '5':
            break
        else:
            print("Invalid input. Try again please.")
    print("All the best on your tasks!")

