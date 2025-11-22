import formInfo from '@ohos.app.form.formInfo';
import formBindingData from '@ohos.app.form.formBindingData';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import Want from '@ohos.app.ability.Want';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    console.info('[EntryFormAbility] onAddForm');
    // Called when the form is added.
    const formData = {
      'temperature': '24°',
      'city': 'Shanghai',
      'condition': 'Sunny',
      'updateTime': new Date().toLocaleTimeString()
    };
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    console.info('[EntryFormAbility] onUpdateForm');
    // Called to notify the form provider to update a specified form.
    const formData = {
      'temperature': '25°',
      'city': 'Shanghai',
      'condition': 'Cloudy',
      'updateTime': new Date().toLocaleTimeString()
    };
    const formInfo = formBindingData.createFormBindingData(formData);
    this.context.updateForm(formId, formInfo);
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
    // Called when the form provider receives form events from the system.
  }

  onFormEvent(formId: string, message: string) {
    // Called when a specified message is received from the form.
    console.info(`[EntryFormAbility] onFormEvent: ${message}`);
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
};
