CREATE TRIGGER after_counter_insert
    AFTER INSERT ON counters
    FOR EACH ROW
    WHEN (SELECT LENGTH(synchronizationAccessToken) FROM settings WHERE id = 1) > 0
BEGIN
    INSERT INTO counters_history (
        name,
        counterCount,
        creationTimeStamp,
        lastModificationTimeStamp,
        counterLimit,
        folderId,
        color,
        counterOrder,
        orderInFolder,
        step,
        note,
        originalId,
        insertTimeStamp,
        operationType,
        synchronizationTimeStamp
    )
    VALUES (
               NEW.name,
               NEW.counterCount,
               NEW.creationTimeStamp,
               NEW.lastModificationTimeStamp,
               NEW.counterLimit,
               NEW.folderId,
               NEW.color,
               NEW.counterOrder,
               NEW.orderInFolder,
               NEW.step,
               NEW.note,
               NEW.id,
               strftime('%s','now'),
               'INSERT',
               NULL
           );
END;

