defmodule Awesome.Fetcher.API do
  # Этот модуль - говнокод
  # Что бы замокать данные которые получает фетчер и не
  # ждать полностью процесс обновления
  # Если без этого модуля делать, то фетчер дохнет в момент
  # подмены модуля и тесты валятся. Если юзать Mox - то подобный модуль будет
  # существовать в любом случае.
  # А если бы я не поленился сразу сделать всё через Экту
  # то говнокод был бы несколько иного рода, т.к.
  # логику автоматического подсоса инфы надо было бы блочить
  # или мутить какой то оверкил с версиями данных.
  # А вот с ETSкой пришлось делать говнокод с возможностью
  # запуска нескольких инстансов фетчера

  def get_data() do
    Awesome.Fetcher.get_data()
  end
end
