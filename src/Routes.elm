module Routes exposing (..)


type alias Model =
    { route : String }


model : Model
model =
    { route = "SignupPage" }


type Msg
    = SignupPage
    | LoginPage
    | HomePage


update : Msg -> Model -> Model
update msg model =
    let
        newModel =
            case msg of
                SignupPage ->
                    "SignupPage"

                LoginPage ->
                    "LoginPage"

                HomePage ->
                    "HomePage"
    in
        { model | route = newModel }


navigate : Model -> Msg -> Model
navigate model destination =
    update destination model
