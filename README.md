# mta_alexa_app
communicates mta api info to alexa

## local development

1. ensure that local PostgreSQL db is running
2. run the sinatra app `ruby app.rb`
3. use elm-live to rebuild the elm code on save: `elm-live src/Main.elm --output=public/elm.js`
4. visit `localhost:4567/elm`

## To-Do:
- Fix alexa request handling etc.
- Add validations when adding a new bus stop
- AJAX
