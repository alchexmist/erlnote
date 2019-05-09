defmodule Erlnote.Seeds do
  
  def run() do
  
    alias Erlnote.Repo
    alias Erlnote.Accounts.User
    alias Erlnote.Tags.Tag
    alias Erlnote.Boards
    alias Erlnote.Boards.Board
    alias Erlnote.Tasks
    alias Erlnote.Tasks.Tasklist
    alias Erlnote.Notes
    alias Erlnote.Notes.{Note, Notepad}

    user1 = Repo.insert!(
    User.registration_changeset(
        %User{},
        %{
            username: "asm", 
            name: "asm", 
            credentials: [%{ 
                email: "asm@example.com", 
                password: "altosecreto"
            }]
        }
    )
    )

    user2 = Repo.insert!(
    User.registration_changeset(
        %User{},
        %{
            name: "jsg",
            username: "jsg",
            credentials: [
                %{
                    email: "jsg@example.com",
                    password: "jsgjsgjsg"
                },
                %{
                    email: "jsg1@example.com",
                    password: "jjjjjjjjj"
                }
            ]
        }
    )
    )

    user3 = Repo.insert!(
    User.registration_changeset(
        %User{},
        %{
            name: "mnmc",
            username: "mnmc",
            credentials: [
                %{
                    email: "mnmc@example.com",
                    password: "mnmcmnmcmnmc"
                },
                %{
                    email: "mnmc1@example.com",
                    password: "mmmmmmmmm"
                }
            ]
        }
    )
    )

    tag1 = Repo.insert!(
    Tag.changeset(
        %Tag{},
        %{
            name: "privado"
        }
    )
    )

    tag2 = Repo.insert!(
    Tag.changeset(
        %Tag{},
        %{
            name: "compartido"
        }
    )
    )

    tag3 = Repo.insert!(
    Tag.changeset(
        %Tag{},
        %{
            name: "personal"
        }
    )
    )

    tag4 = Repo.insert!(
    Tag.changeset(
        %Tag{},
        %{
            name: "profesional"
        }
    )
    )

    {:ok, %Board{} = board1} = Boards.create_board(user1.id)
    {:ok, %Board{} = board1} = Boards.update_board(user1.id, board1.id, %{title: "Pizarra Uno", text: "En un lugar de la Mancha, de cuyo nombre no quiero acordarme, no ha mucho tiempo que vivía un hidalgo de los de lanza en astillero, adarga antigua ..."})
    {:ok, _} = Boards.link_board_to_user(user1.id, board1.id, user2.id)
    {:ok, _} = Boards.link_board_to_user(user1.id, board1.id, user3.id)

    {:ok, %Board{} = board2} = Boards.create_board(user2.id)
    {:ok, %Board{} = board2} = Boards.update_board(user2.id, board2.id, %{title: "Pizarra Dos", text: "Parse error before la sota de bastos ..."})
    {:ok, _} = Boards.link_board_to_user(user2.id, board2.id, user1.id)

    {:ok, %Board{} = board3} = Boards.create_board(user3.id)
    {:ok, %Board{} = _board3} = Boards.update_board(user3.id, board3.id, %{title: "Pizarra Tres", text: "Segmentation fault (coredumped)"})

    {:ok, %Tasklist{} = tasklist1} = Tasks.create_tasklist(user1.id)
    {:ok, %Tasklist{} = tasklist1} = Tasks.update_tasklist(user1.id, tasklist1.id, %{title: "Lista de tareas 1"})
    {:ok, _} = Tasks.link_tasklist_to_user(user1.id, tasklist1.id, user2.id, true, true)
    {:ok, _} = Tasks.link_tasklist_to_user(user1.id, tasklist1.id, user3.id, true, true)
    {:ok, _} = Tasks.link_tag_to_tasklist(tasklist1.id, user1.id, tag2.name)
    {:ok, _} = Tasks.link_tag_to_tasklist(tasklist1.id, user1.id, tag4.name)
    {:ok, _} = Tasks.add_task_to_tasklist(user1.id, tasklist1.id, %{description: "Descripción Uno", end_datetime: "2010-04-17T18:00:00Z", name: "Tarea 1 Lista 1", priority: "LOW", start_datetime: "2010-04-17T14:00:00Z", state: "INPROGRESS"})
    {:ok, _} = Tasks.add_task_to_tasklist(user1.id, tasklist1.id, %{description: "Descripción Dos", end_datetime: "2011-04-17T18:00:00Z", name: "Tarea 2 Lista 1", priority: "NORMAL", start_datetime: "2011-04-17T14:00:00Z", state: "INPROGRESS"})
    {:ok, _} = Tasks.add_task_to_tasklist(user1.id, tasklist1.id, %{description: "Descripción Tres", end_datetime: "2012-04-17T18:00:00Z", name: "Tarea 3 Lista 1", priority: "HIGH", start_datetime: "2012-04-17T14:00:00Z", state: "FINISHED"})

    {:ok, %Tasklist{} = tasklist2} = Tasks.create_tasklist(user2.id)
    {:ok, %Tasklist{} = tasklist2} = Tasks.update_tasklist(user2.id, tasklist2.id, %{title: "Lista de tareas 2"})
    {:ok, _} = Tasks.link_tasklist_to_user(user2.id, tasklist2.id, user1.id, true, true)
    {:ok, _} = Tasks.link_tasklist_to_user(user2.id, tasklist2.id, user3.id, true, true)
    {:ok, _} = Tasks.link_tag_to_tasklist(tasklist2.id, user2.id, tag2.name)
    {:ok, _} = Tasks.link_tag_to_tasklist(tasklist2.id, user2.id, tag4.name)
    {:ok, _} = Tasks.add_task_to_tasklist(user2.id, tasklist2.id, %{description: "Descripción Uno", end_datetime: "2013-04-17T18:00:00Z", name: "Tarea 1 Lista 2", priority: "LOW", start_datetime: "2013-04-17T14:00:00Z", state: "INPROGRESS"})
    {:ok, _} = Tasks.add_task_to_tasklist(user2.id, tasklist2.id, %{description: "Descripción Dos", end_datetime: "2014-04-17T18:00:00Z", name: "Tarea 2 Lista 2", priority: "NORMAL", start_datetime: "2014-04-17T14:00:00Z", state: "INPROGRESS"})
    {:ok, _} = Tasks.add_task_to_tasklist(user2.id, tasklist2.id, %{description: "Descripción Tres", end_datetime: "2015-04-17T18:00:00Z", name: "Tarea 3 Lista 2", priority: "HIGH", start_datetime: "2015-04-17T14:00:00Z", state: "FINISHED"})

    {:ok, %Tasklist{} = tasklist3} = Tasks.create_tasklist(user3.id)
    {:ok, %Tasklist{} = tasklist3} = Tasks.update_tasklist(user3.id, tasklist3.id, %{title: "Lista de tareas 3"})
    {:ok, _} = Tasks.link_tag_to_tasklist(tasklist3.id, user3.id, tag1.name)
    {:ok, _} = Tasks.link_tag_to_tasklist(tasklist3.id, user3.id, tag3.name)
    {:ok, _} = Tasks.add_task_to_tasklist(user3.id, tasklist3.id, %{description: "Descripción Uno", end_datetime: "2016-04-17T18:00:00Z", name: "Tarea 1 Lista 3", priority: "LOW", start_datetime: "2016-04-17T14:00:00Z", state: "INPROGRESS"})
    {:ok, _} = Tasks.add_task_to_tasklist(user3.id, tasklist3.id, %{description: "Descripción Dos", end_datetime: "2017-04-17T18:00:00Z", name: "Tarea 2 Lista 3", priority: "NORMAL", start_datetime: "2017-04-17T14:00:00Z", state: "INPROGRESS"})
    {:ok, _} = Tasks.add_task_to_tasklist(user3.id, tasklist3.id, %{description: "Descripción Tres", end_datetime: "2018-04-17T18:00:00Z", name: "Tarea 3 Lista 3", priority: "HIGH", start_datetime: "2018-04-17T14:00:00Z", state: "FINISHED"})

    {:ok, %Note{} = note1} = Notes.create_note(user1.id)
    {:ok, %Note{} = note1} = Notes.update_note(user1.id, note1.id, %{title: "Nota Uno", body: "¡Un texto cualquiera!."})
    {:ok, _} = Notes.link_note_to_user(user1.id, note1.id, user2.id, true, true)
    {:ok, _} = Notes.link_note_to_user(user1.id, note1.id, user3.id, true, true)
    {:ok, _} = Notes.link_tag_to_note(note1.id, user1.id, tag2.name)
    {:ok, _} = Notes.link_tag_to_note(note1.id, user1.id, tag4.name)

    {:ok, %Note{} = note2} = Notes.create_note(user2.id)
    {:ok, %Note{} = note2} = Notes.update_note(user2.id, note2.id, %{title: "Nota Dos", body: "¡Otro texto cualquiera!."})
    {:ok, _} = Notes.link_note_to_user(user2.id, note2.id, user1.id, true, true)
    {:ok, _} = Notes.link_note_to_user(user2.id, note2.id, user3.id, true, true)
    {:ok, _} = Notes.link_tag_to_note(note2.id, user2.id, tag2.name)
    {:ok, _} = Notes.link_tag_to_note(note2.id, user2.id, tag4.name)

    {:ok, %Note{} = note3} = Notes.create_note(user3.id)
    {:ok, %Note{} = _note3} = Notes.update_note(user3.id, note3.id, %{title: "Nota Tres", body: "La simplicidad, o el arte de maximizar la cantidad de trabajo no realizado, es esencial."})
    {:ok, _} = Notes.link_tag_to_note(note3.id, user3.id, tag1.name)
    {:ok, _} = Notes.link_tag_to_note(note3.id, user3.id, tag3.name)

    {:ok, %Notepad{} = notepad1} = Notes.create_notepad(user1.id)
    {:ok, %Notepad{} = notepad1} = Notes.update_notepad(notepad1, %{name: "Mi bloc de notas"})
    {:ok, _} = Notes.link_tag_to_notepad(notepad1.id, user1.id, tag1.name)
    {:ok, _} = Notes.link_tag_to_notepad(notepad1.id, user1.id, tag3.name)
    {:ok, _} = Notes.add_note_to_notepad(note1.id, notepad1.id)
    {:ok, _} = Notes.add_note_to_notepad(note2.id, notepad1.id)

    :ok
    
  end

end