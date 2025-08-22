trigger AccountTrigger on Account (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        for (Account acc : Trigger.new) {
            GoogleDriveServiceFuture.createFolderFuture(acc.Id, acc.Name);
        }
    }
}