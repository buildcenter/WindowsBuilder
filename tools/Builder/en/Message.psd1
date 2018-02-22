# Localized	24/5/2017 2:06 PM (GMT)	410:2.92.0533	Message.psd1
# Builder PBLocalizedData.en-US

ConvertFrom-StringData @'

# ---- [ Localized Data ] ---------------------------------------------

Err_InvalidTaskName = Task name cannot be null or empty string.
Err_TaskNameDoesNotExist = Task does not exist: {0}
Err_CircularReference = The task has circular references: {0}
Err_MissingActionParameter = Action parameter must be specified when using PreAction or PostAction parameters: {0}
Err_CorruptCallStack = Call stack was corrupt (expected '{0}', but got '{1}').
Err_EnvPathDirNotFound  = The environmental path specified does not exist, or is not a filesystem directory: {0}
Err_BadCommand = Error executing command: {0}
Err_DefaultTaskCannotHaveAction  = Do not specify an action for the 'default' task.
Er_DuplicateTaskName = Task has already been defined: {0}
Err_DuplicateAliasName = Alias has already been defined: {0}
Err_InvalidIncludePath = Unable to include a file because it was not found: {0}
Err_BuildFileNotFound = Unable to find build file: {0}
Err_NoDefaultTask = A 'default' task is required.
Err_LoadingModule = Error loading module: {0}
Err_LoadConfig = Error loading build configuration: {0}
RequiredVarNotSet = Variable '{0}' must be set to run task '{1}'.
PostconditionFailed = Postcondition failed for task: {0}
PreconditionWasFalse = Precondition was false, not executing task: {0}
ContinueOnError = Error in task '{0}': {1}
BuildSuccess = Build succeeded!
RetryMessage = Attempt {0}/{1} failed, retrying in {2} second...
BuildTimeReportTitle = Build Time Report
Divider = ----------------------------------------------------------------------
ErrorHeaderText = An error has occured. See details below:
ErrorLabel = Error
VariableLabel = Script variables:
DefaultTaskNameFormat = Executing {0}
UnknownError = An unknown error has occured.

# ---- [ /Localized Data ] --------------------------------------------
'@
